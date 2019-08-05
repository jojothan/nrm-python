{-# LANGUAGE QuasiQuotes #-}

{-|
Module      : codegen
Description : codegen
Copyright   : (c) 2019, UChicago Argonne, LLC.
License     : BSD3
Maintainer  : fre@freux.fr
-}
module Codegen
  ( main
  )
where

import Codegen.CHeader
import Codegen.Schema (generatePretty)
import NeatInterpolation
import Nrm.Types.Messaging.DownstreamEvent
import Nrm.Types.Messaging.UpstreamPub
import Nrm.Types.Messaging.UpstreamRep
import Nrm.Types.Messaging.UpstreamReq
import Protolude hiding (Rep)

main :: IO ()
main = do
  writeFile "../gen/nrm_messaging.h" $ license <> libnrmHeader
  writeFile "../gen/upstreamPub.json" upstreamPubSchema
  writeFile "../gen/upstreamReq.json" upstreamReqSchema
  writeFile "../gen/upstreamRep.json" upstreamRepSchema
  writeFile "../gen/downstreamEvent.json" downstreamEventSchema

upstreamReqSchema :: Text
upstreamReqSchema = generatePretty (Proxy :: Proxy Req)

upstreamRepSchema :: Text
upstreamRepSchema = generatePretty (Proxy :: Proxy Rep)

upstreamPubSchema :: Text
upstreamPubSchema = generatePretty (Proxy :: Proxy Pub)

downstreamEventSchema :: Text
downstreamEventSchema = generatePretty (Proxy :: Proxy Event)

libnrmHeader :: Text
libnrmHeader = toHeader $ toCHeader (Proxy :: Proxy Event)

license :: Text
license =
  [text|
    /*******************************************************************************
     * Copyright 2019 UChicago Argonne, LLC.
     * (c.f. AUTHORS, LICENSE)
     *
     * SPDX-License-Identifier: BSD-3-Clause
    *******************************************************************************/

    /*
     *
     *   THIS FILE WAS AUTOMATICALLY GENERATED BY NRM. DO NOT MODIFY MANUALLY.
     *
    */

  |]
