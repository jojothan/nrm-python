{-|
Module      : NRM.Types.Process
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module NRM.Types.Process
  ( Cmd (..)
  , CmdCore (..)
  , CmdSpec (..)
  , mkCmd
  , registerPID
  , ProcessID (..)
  , ProcessState (..)
  , blankState
  , isDone
  , ThreadID (..)
  , TaskID (..)
  , CmdID (..)
  , Command (..)
  , Arguments (..)
  , Arg (..)
  , Env (..)
  , nextCmdID
  , toText
  , fromText
  )
where

import qualified Data.Aeson as A
import Data.Aeson
import Data.JSON.Schema
import NRM.Orphans.ExitCode ()
import Data.MessagePack
import Data.String (IsString (..))
import qualified Data.UUID as U
import Data.UUID.V1
import Generics.Generic.Aeson
import qualified NRM.Types.UpstreamClient as UC
import Protolude
import qualified System.Posix.Types as P
import Prelude (fail)

data ProcessState
  = ProcessState
      { ended :: Maybe ExitCode
      , stdoutFinished :: Bool
      , stderrFinished :: Bool
      }
  deriving (Show, Generic, MessagePack, FromJSON, ToJSON)

blankState :: ProcessState
blankState = ProcessState Nothing False False

isDone :: ProcessState -> Maybe ExitCode
isDone ProcessState {..} = case ended of
  Just exc | stdoutFinished && stderrFinished -> Just exc
  _ -> Nothing

data CmdSpec
  = CmdSpec
      { cmd :: Command
      , args :: Arguments
      , env :: Env
      }
  deriving (Show, Generic, MessagePack, FromJSON, ToJSON)

data CmdCore
  = CmdCore
      { cmdPath :: Command
      , arguments :: Arguments
      , upstreamClientID :: Maybe UC.UpstreamClientID
      }
  deriving (Show, Generic, MessagePack, FromJSON, ToJSON)

data Cmd
  = Cmd
      { cmdCore :: CmdCore
      , pid :: ProcessID
      , processState :: ProcessState
      }
  deriving (Show, Generic, MessagePack, FromJSON, ToJSON)

instance JSONSchema CmdSpec where

  schema = gSchema

instance JSONSchema Cmd where

  schema = gSchema

instance JSONSchema CmdCore where

  schema = gSchema

instance JSONSchema ProcessState where

  schema = gSchema

mkCmd :: CmdSpec -> Maybe UC.UpstreamClientID -> CmdCore
mkCmd s clientID = CmdCore {cmdPath = cmd s, arguments = args s, upstreamClientID = clientID}

registerPID :: CmdCore -> ProcessID -> Cmd
registerPID c pid = Cmd {cmdCore = c, processState = blankState ,..}

newtype TaskID = TaskID Int
  deriving (Eq, Ord, Show, Read, Generic, MessagePack)

newtype ThreadID = ThreadID Int
  deriving (Eq, Ord, Show, Read, Generic, MessagePack)

newtype ProcessID = ProcessID P.CPid
  deriving (Eq, Ord, Show, Read, Generic)

newtype Arg = Arg Text
  deriving (Show, Generic, MessagePack)

instance StringConv Arg Text where

  strConv _ (Arg x) = toS x

newtype Command = Command Text
  deriving (Show, Generic, MessagePack)

instance StringConv Command Text where

  strConv _ (Command x) = toS x

newtype Arguments = Arguments [Arg]
  deriving (Show, Generic, MessagePack)

newtype Env = Env [(Text, Text)]
  deriving (Show, Generic, MessagePack)

instance ToJSON Env where

  toJSON = gtoJson

instance FromJSON Env where

  parseJSON = gparseJson

instance JSONSchema Env where

  schema = gSchema

instance ToJSON ThreadID where

  toJSON = gtoJson

instance FromJSON ThreadID where

  parseJSON = gparseJson

instance JSONSchema ThreadID where

  schema = gSchema

instance ToJSON TaskID where

  toJSON = gtoJson

instance FromJSON TaskID where

  parseJSON = gparseJson

instance JSONSchema TaskID where

  schema = gSchema

instance MessagePack ProcessID where

  toObject (ProcessID x) = toObject (fromIntegral x :: Int)

  fromObject x = ProcessID . P.CPid <$> fromObject x

instance ToJSON ProcessID where

  toJSON (ProcessID x) = toJSON (fromIntegral x :: Int)

instance FromJSON ProcessID where

  parseJSON = fmap (ProcessID . P.CPid) . parseJSON

instance JSONSchema ProcessID where

  schema Proxy = schema (Proxy :: Proxy Int)

instance ToJSON Command where

  toJSON = gtoJson

instance FromJSON Command where

  parseJSON = gparseJson

instance JSONSchema Command where

  schema = gSchema

instance ToJSON Arguments where

  toJSON = gtoJson

instance FromJSON Arguments where

  parseJSON = gparseJson

instance JSONSchema Arguments where

  schema = gSchema

instance ToJSON Arg where

  toJSON = gtoJson

instance FromJSON Arg where

  parseJSON = gparseJson

instance JSONSchema Arg where

  schema = gSchema

newtype CmdID = CmdID U.UUID
  deriving (Show, Eq, Ord, Generic, ToJSONKey, FromJSONKey)

instance IsString CmdID where

  fromString x = fromMaybe (panic "couldn't decode cmdID in FromString instance") (decode $ toS x)

nextCmdID :: IO (Maybe CmdID)
nextCmdID = fmap CmdID <$> nextUUID

parseCmdID :: Text -> Maybe CmdID
parseCmdID = fmap CmdID <$> U.fromText

toText :: CmdID -> Text
toText (CmdID u) = U.toText u

fromText :: Text -> Maybe CmdID
fromText = fmap CmdID <$> U.fromText

instance ToJSON CmdID where

  toJSON = gtoJson

instance FromJSON CmdID where

  parseJSON = gparseJson

instance JSONSchema CmdID where

  schema Proxy = schema (Proxy :: Proxy Text)

instance MessagePack CmdID where

  toObject (CmdID c) = toObject $ U.toText c

  fromObject x =
    fromObject x >>= \y ->
      case parseCmdID y of
        Nothing -> fail "Couldn't parse CmdID"
        Just t -> return t