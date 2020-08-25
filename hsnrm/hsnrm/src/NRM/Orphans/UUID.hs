{-# LANGUAGE DerivingVia #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

-- |
-- Module      : NRM.Orphans.UUID
-- Copyright   : (c) UChicago Argonne, 2019
-- License     : BSD3
-- Maintainer  : fre@freux.fr
module NRM.Orphans.UUID
  (
  )
where

import Data.Functor.Contravariant (contramap)
import Data.JSON.Schema
import Data.Maybe (fromJust)
import Data.MessagePack
import Data.UUID as U (UUID, fromText, toText)
import Dhall
import Protolude

instance JSONSchema UUID where
  schema Proxy = schema (Proxy :: Proxy Text)

instance MessagePack UUID where

  toObject = toObject . U.toText

  fromObject x =
    fromObject x >>= \y ->
      case fromText y of
        Nothing -> panic "Couldn't parse CmdID"
        Just t -> return t

instance FromDhall UUID where
  autoWith = fmap (fromJust . U.fromText) . autoWith

instance ToDhall UUID where
  injectWith = fmap (contramap U.toText) Dhall.injectWith