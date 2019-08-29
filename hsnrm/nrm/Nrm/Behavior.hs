{-|
Module      : Nrm.Behavior
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module Nrm.Behavior
  ( -- * Nrm's core logic.
    behavior
  , -- * The Event specification
    NrmEvent (..)
  , -- * The Behavior specification
    Behavior (..)
  , CmdStatus (..)
  )
where

import qualified Data.Map as DM
import Data.MessagePack
import qualified Nrm.Classes.Messaging as M
import Nrm.NrmState
import qualified Nrm.Types.Configuration as Cfg
import qualified Nrm.Types.Container as Ct
import Nrm.Types.Messaging.DownstreamEvent as DEvent
import qualified Nrm.Types.Messaging.UpstreamPub as UPub
import qualified Nrm.Types.Messaging.UpstreamRep as URep
import qualified Nrm.Types.Messaging.UpstreamReq as UReq
import Nrm.Types.NrmState
import Nrm.Types.Process
import qualified Nrm.Types.UpstreamClient as UC
import Protolude

-- | The Behavior datatype describes an event from the runtime on which to react.
data NrmEvent
  = -- | A Request was received on the Upstream API.
    Req UC.UpstreamClientID UReq.Req
  | -- | Registering a child process.
    RegisterCmd CmdID CmdStatus
  | -- | Event from the application side.
    DownstreamEvent DEvent.Event
  | -- | Stdin/stdout data from the app side.
    DoOutput CmdID URep.OutputType Text
  | -- | Child death event
    ChildDied ProcessID ExitCode
  | -- | Sensor callback
    DoSensor
  | -- | Control loop calback
    DoControl
  | -- | Shutting down the daemon
    DoShutdown

-- | The Launch status of a command, for registration.
data CmdStatus
  = -- | In case the command to start a child succeeded, mark it as registered and provide its PID.
    Launched ProcessID
  | -- | In case the command to start a child failed.
    NotLaunched
  deriving (Generic, MessagePack)

-- | The Behavior datatype encodes a behavior to be executed by the NRM runtime.
data Behavior
  = -- | The No-Op
    NoBehavior
  | -- | Log a message
    Log Text
  | -- | Reply to an upstream client.
    Rep UC.UpstreamClientID URep.Rep
  | -- | Publish a message on upstream
    Pub UPub.Pub
  | -- | Start a child process
    StartChild CmdID Command Arguments Env
  | -- | Kill children processes and send some messages back upstream.
    KillChildren [CmdID] [(UC.UpstreamClientID, URep.Rep)]
  | -- | Pop one child process and may send a message back upstream.
    ClearChild CmdID (Maybe (UC.UpstreamClientID, URep.Rep))
  deriving (Generic)

-- | The behavior function contains the main logic of the NRM daemon. It changes the state and
-- produces an associated behavior to be executed by the runtime. This contains the container
-- management logic, the sensor callback logic, the control loop callback logic.
behavior :: Cfg.Cfg -> NrmState -> NrmEvent -> IO (NrmState, Behavior)
behavior _ st (DoOutput cmdID outputType content) =
  return $ case DM.lookup cmdID (cmdIDMap st) of
    Just (c, containerID, container) -> case (upstreamClientID . cmdCore) c of
      Just ucID ->
        if content == ""
        then
          let newPstate = case outputType of
                URep.StdoutOutput -> (processState c) {stdoutFinished = True}
                URep.StderrOutput -> (processState c) {stderrFinished = True}
           in ( case isDone newPstate of
                  Just _ -> undefined
                  Nothing ->
                    insertContainer containerID
                      (Ct.insertCmd cmdID (c {processState = newPstate}) container)
                      st
              , Rep ucID $ URep.RepEndStream (URep.EndStream outputType)
              )
        else
          ( st
          , Rep ucID $ case outputType of
            URep.StdoutOutput ->
              URep.RepStdout $ URep.Stdout
                { URep.stdoutContainerID = containerID
                , stdoutPayload = content
                }
            URep.StderrOutput ->
              URep.RepStderr $ URep.Stderr
                { URep.stderrContainerID = containerID
                , stderrPayload = content
                }
          )
      Nothing -> (st, Log "This command does not have a registered upstream client.")
    Nothing -> (st, Log "No such command was found in the NRM state.")
behavior _ st (RegisterCmd cmdID cmdstatus) = case cmdstatus of
  NotLaunched ->
    return $ fromMaybe (st, NoBehavior) $
      registerFailed cmdID st >>= \(st', _, _, cmdCore) ->
      upstreamClientID cmdCore <&> \x ->
        (st', Rep x (URep.RepStartFailure URep.StartFailure))
  Launched pid ->
    mayLog st $
      registerLaunched cmdID pid st <&> \(st', containerID, maybeClientID) ->
      fromMaybe (st', NoBehavior) $
        maybeClientID <&> \clientID ->
        ( st'
        , Rep clientID (URep.RepStart (URep.Start containerID cmdID))
        )
behavior c st (Req clientid msg) = case msg of
  UReq.ReqContainerList _ ->
    return (st, Rep clientid (URep.RepList rep))
    where
      rep = URep.ContainerList (DM.toList (containers st))
  UReq.ReqGetState _ ->
    return (st, Rep clientid (URep.RepGetState (URep.GetState st)))
  UReq.ReqGetConfig _ ->
    return (st, Rep clientid (URep.RepGetConfig (URep.GetConfig c)))
  UReq.ReqRun UReq.Run {..} -> do
    cmdID <- nextCmdID <&> fromMaybe (panic "couldn't generate next cmd id")
    return
      ( registerAwaiting cmdID
          (mkCmd spec (if detachCmd then Nothing else Just clientid))
          runContainerID .
          createContainer runContainerID $
          st
      , StartChild cmdID (cmd spec) (args spec) (env spec)
      )
  UReq.ReqKillContainer UReq.KillContainer {..} -> do
    let (maybeContainer, st') = removeContainer killContainerID st
    return
      ( st'
      , fromMaybe (Rep clientid $ URep.RepNoSuchContainer URep.NoSuchContainer)
        ( maybeContainer <&> \container ->
          KillChildren (DM.keys $ Ct.cmds container) $
            (clientid, URep.RepContainerKilled (URep.ContainerKilled killContainerID)) :
            catMaybes
              ( (upstreamClientID . cmdCore <$> DM.elems (Ct.cmds container)) <&>
                fmap (,URep.RepThisCmdKilled URep.ThisCmdKilled)
              )
        )
      )
  UReq.ReqSetPower _ -> return (st, NoBehavior)
  UReq.ReqKillCmd UReq.KillCmd {..} ->
    return $ fromMaybe (st, NoBehavior) $
      removeCmd (KCmdID killCmdID) st <&> \(info, _, cmd, containerID, st') ->
      ( st'
      , KillChildren [killCmdID] $
        ( clientid
        , case info of
          CmdRemoved -> URep.RepCmdKilled (URep.CmdKilled killCmdID)
          ContainerRemoved -> URep.RepContainerKilled (URep.ContainerKilled containerID)
        ) :
        maybe [] (\x -> [(x, URep.RepThisCmdKilled URep.ThisCmdKilled)]) (upstreamClientID . cmdCore $ cmd)
      )
behavior _ st (ChildDied pid exitcode) =
  return $
    DM.lookup pid (pidMap st) & \case
    Just (cmdID, cmd, containerID, container) ->
      let newPstate = (processState cmd) {ended = Just exitcode}
       in case isDone newPstate of
            Just _ -> case removeCmd (KProcessID pid) st of
              Just (_, _, _, _, st') ->
                ( st'
                , ClearChild cmdID
                  ( (,URep.RepCmdEnded (URep.CmdEnded exitcode)) <$>
                    (upstreamClientID . cmdCore $ cmd)
                  )
                )
              Nothing -> (st, panic "Error during command removal from NRM state")
            Nothing ->
              ( insertContainer containerID
                  (Ct.insertCmd cmdID cmd {processState = newPstate} container)
                  st
              , ClearChild cmdID
                ( (,URep.RepCmdEnded (URep.CmdEnded exitcode)) <$>
                  (upstreamClientID . cmdCore $ cmd)
                )
              )
    Nothing -> (st, Log "No such PID in NRM's state.")
behavior _ st DoSensor = return (st, NoBehavior)
behavior _ st DoControl = return (st, NoBehavior)
behavior _ st DoShutdown = return (st, NoBehavior)
behavior _ st (DownstreamEvent msg) = case msg of
  DEvent.ThreadStart _ -> return (st, NoBehavior)
  DEvent.ThreadProgress _ _ -> return (st, NoBehavior)
  DEvent.ThreadPhaseContext _ _ -> return (st, NoBehavior)
  DEvent.ThreadExit _ -> return (st, NoBehavior)
  DEvent.CmdStart _ -> return (st, NoBehavior)
  DEvent.CmdPerformance _ _ -> return (st, NoBehavior)
  DEvent.CmdExit _ -> return (st, NoBehavior)

-- | The sensitive unpacking that has to be pattern-matched on the python side.
-- These toObject/fromObject functions do not correspond to each other and the instance
-- just exists for passing the behavior to the python runtime.
instance MessagePack Behavior where

  toObject NoBehavior = toObject ("noop" :: Text)
  toObject (Log msg) = toObject ("log" :: Text, msg)
  toObject (Pub msg) = toObject ("publish" :: Text, M.encodeT msg)
  toObject (Rep clientid msg) =
    toObject ("reply" :: Text, clientid, M.encodeT msg)
  toObject (StartChild cmdID cmd args env) =
    toObject ("cmd" :: Text, cmdID, cmd, args, env)
  toObject (KillChildren cmdIDs reps) =
    toObject
      ( "kill" :: Text
      , cmdIDs
      , (\(clientid, msg) -> (clientid, M.encodeT msg)) <$> reps
      )
  toObject (ClearChild cmdID maybeRep) =
    toObject
      ( "pop" :: Text
      , cmdID
      , (\(clientid, msg) -> (clientid, M.encodeT msg)) <$> toList maybeRep
      )

  fromObject x = to <$> gFromObject x

mayLog :: NrmState -> Either Text (NrmState, Behavior) -> IO (NrmState, Behavior)
mayLog st =
  return . \case
    Left e -> (st, Log e)
    Right x -> x
