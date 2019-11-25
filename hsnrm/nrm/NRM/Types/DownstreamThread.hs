{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE TypeApplications #-}
{-# OPTIONS_GHC -fno-warn-missing-local-signatures #-}

-- |
-- Module      : NRM.Types.DownstreamThread
-- Copyright   : (c) UChicago Argonne, 2019
-- License     : BSD3
-- Maintainer  : fre@freux.fr
module NRM.Types.DownstreamThread
  ( DownstreamThread (..),
  )
where

import Control.Lens hiding ((...))
import Data.Aeson
import Data.Generics.Product
import Data.JSON.Schema
import Data.Map as DM
import Data.MessagePack
import LensMap.Core
import NRM.Classes.Messaging
import NRM.Types.DownstreamThreadID
import NRM.Types.MemBuffer
import NRM.Types.Sensor as S
import NRM.Types.Units
import Numeric.Interval
import Protolude

data DownstreamThread
  = DownstreamThread
      { maxValue :: Progress,
        ratelimit :: Frequency,
        dtLastReferenceMeasurements :: MemBuffer Double
      }
  deriving (Eq, Ord, Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON DownstreamThread

instance
  HasLensMap (DownstreamThreadID, DownstreamThread)
    ActiveSensorKey
    ActiveSensor
  where
  lenses (downstreamThreadID, downstreamThread) =
    DM.singleton
      (DownstreamThreadKey downstreamThreadID)
      (ScopedLens (_2 . lens getter setter))
    where
      getter (DownstreamThread _maxValue ratelimit dtLastRef) =
        ActiveSensor
          { activeMeta = SensorMeta
              { tags = [S.Maximize, S.DownstreamThreadSignal],
                range = 0 ... (maxValue downstreamThread & fromProgress & fromIntegral),
                lastReferenceMeasurements = dtLastRef
              },
            maxFrequency = ratelimit,
            process = identity
          }
      setter dc activeSensor =
        dc & field @"maxValue"
          .~ progress (floor . sup $ range (meta activeSensor))
            & field @"dtLastReferenceMeasurements"
          .~ lastReferenceMeasurements (meta activeSensor)
