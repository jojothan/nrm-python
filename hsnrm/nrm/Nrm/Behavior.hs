{-|
Module      : Nrm.Behavior
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module Nrm.Behavior
  ( behavior
  , Behavior (..)
  , SendAPI (..)
  , RecvAPI (..)
  , NrmEvent (..)
  )
where

import Data.MessagePack
import Nrm.Classes.Messaging
import Nrm.Types.Process
import Nrm.Types.Messaging.DownstreamEvent as D
import qualified Nrm.Types.NrmState as S
import Protolude

data SendAPI = UpstreamPub | UpstreamRep
  deriving (Generic)

deriving instance MessagePack SendAPI

data RecvAPI = DownstreamEvent | UpstreamReq
  deriving (Generic)

deriving instance MessagePack RecvAPI

data Behavior = NoBehavior | Send SendAPI ByteString | StartChild Command Arguments
  deriving (Generic)

deriving instance MessagePack Behavior

data NrmEvent = Recv RecvAPI ByteString | DoSensor | DoControl | DoShutdown | DoChildren
  deriving (Generic)

deriving instance MessagePack NrmEvent

behavior :: NrmEvent -> S.NrmState -> IO (S.NrmState, Behavior)
behavior (Recv DownstreamEvent msg) st = case decode msg of
  Just x -> case x of
    D.LibnrmStart _  -> return (st,NoBehavior)
    D.LibnrmProgress _ _  -> return (st,NoBehavior)
    D.LibnrmPhaseContext _ _ -> return (st,NoBehavior)
    D.LibnrmExit _  -> return (st,NoBehavior)
    D.PerfwrapperStart _  -> return (st,NoBehavior)
    D.PerfwrapperPerformance _ _ -> return (st,NoBehavior)
    D.PerfwrapperExit _ -> return (st,NoBehavior)
  Nothing -> return (st, NoBehavior)
behavior (Recv UpstreamReq _msg) st = return (st, NoBehavior)
behavior DoSensor st = return (st, NoBehavior)
behavior DoControl st = return (st, NoBehavior)
behavior DoShutdown st = return (st, NoBehavior)
behavior DoChildren st = return (st, NoBehavior)
