{-|
Module      : Nrm.Types.Messaging.DownstreamEvent
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module Nrm.Types.Messaging.DownstreamEvent
  ( Event (..)
  , Progress (..)
  , PhaseContext (..)
  , Performance (..)
  )
where

import qualified Nrm.Classes.Messaging as M
import qualified Nrm.Types.Messaging.DownstreamEvent.JSON as J
import qualified Nrm.Types.DownstreamClient as D
import qualified Nrm.Types.Units as U
import Protolude

data Event
  = LibnrmStart D.DownstreamLibnrmID
  | LibnrmProgress D.DownstreamLibnrmID Progress
  | LibnrmPhaseContext D.DownstreamLibnrmID PhaseContext
  | LibnrmExit D.DownstreamLibnrmID
  | PerfwrapperStart D.DownstreamPerfID
  | PerfwrapperPerformance D.DownstreamPerfID Performance
  | PerfwrapperExit D.DownstreamPerfID

newtype Performance
  = Performance
      { perf :: U.Operations
      }

newtype Progress
  = Progress
      { payload :: U.Progress
      }

data PhaseContext
  = PhaseContext
      { cpu :: Int
      , startcompute :: Int
      , endcompute :: Int
      , startbarrier :: Int
      , endbarrier :: Int
      }

instance M.NrmMessage Event J.Event where

  toJ = panic "need to implement toJ for DownstreamEvent"

  {-toJ = \case-}
  {-EventStart Start {..} -> J.Start-}
  {-{ container_uuid = C.toText startContainerID-}
  {-, application_uuid = D.toText startDownstreamID-}
  {-}-}
  {-EventExit Exit {..} -> J.Exit-}
  {-{ application_uuid = D.toText exitDownstreamID-}
  {-}-}
  {-EventPerformance Performance {..} -> J.Performance-}
  {-{ container_uuid = C.toText performanceContainerID-}
  {-, application_uuid = D.toText performanceDownstreamID-}
  {-, perf = o-}
  {-}-}
  {-where-}
  {-(U.Operations o) = perf-}
  {-EventProgress Progress {..} -> J.Progress-}
  {-{ application_uuid = D.toText progressDownstreamID-}
  {-, payload = p-}
  {-}-}
  {-where-}
  {-(U.Progress p) = payload-}
  {-EventPhaseContext PhaseContext {..} -> J.PhaseContext {..}-}
  fromJ = panic "need to implement toJ for DownstreamEvent"

{-fromJ = \case-}
{-J.Start {..} ->-}
{-EventStart $ Start-}
{-{ startContainerID = C.parseContainerID container_uuid-}
{-, startDownstreamID = fromMaybe-}
{-(panic "DownstreamEvent fromJ error on Application UUID")-}
{-(D.parseDownstreamID application_uuid)-}
{-}-}
{-J.Exit {..} ->-}
{-EventExit $ Exit-}
{-{ exitDownstreamID = fromMaybe-}
{-(panic "DownstreamEvent fromJ error on Application UUID")-}
{-(D.parseDownstreamID application_uuid)-}
{-}-}
{-J.Performance {..} ->-}
{-EventPerformance $ Performance-}
{-{ performanceContainerID = C.parseContainerID container_uuid-}
{-, performanceDownstreamID = fromMaybe-}
{-(panic "DownstreamEvent fromJ error on Application UUID")-}
{-(D.parseDownstreamID application_uuid)-}
{-, perf = U.Operations perf-}
{-}-}
{-J.Progress {..} ->-}
{-EventProgress $ Progress-}
{-{ progressDownstreamID = fromMaybe-}
{-(panic "DownstreamEvent fromJ error on Application UUID")-}
{-(D.parseDownstreamID application_uuid)-}
{-, payload = U.Progress payload-}
{-}-}
{-J.PhaseContext {..} -> EventPhaseContext PhaseContext {..}-}
