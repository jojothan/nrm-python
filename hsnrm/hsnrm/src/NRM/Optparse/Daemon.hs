{-# LANGUAGE ScopedTypeVariables #-}

-- |
-- Module      : NRM.Optparse.Daemon
-- Copyright   : (c) UChicago Argonne, 2019
-- License     : BSD3
-- Maintainer  : fre@freux.fr
module NRM.Optparse.Daemon
  ( opts,
    processType,
    SourceType (..),
    FinallySource (..),
    ext,
  )
where

import Codegen.Dhall
import qualified Data.Aeson as J
import Data.Aeson.Extra.Merge
import qualified Data.ByteString as B (getContents)
import Data.Default
import Data.Either.Validation as V
import qualified Data.Yaml as Y
import qualified Dhall
import qualified Dhall.Core as Dhall
import Dhall.JSON as DJ
import Dhall.JSONToDhall as JSONToDhall
import qualified Dhall.Src as Dhall
import NRM.Types.Configuration
import Options.Applicative
import Protolude
import System.Directory
import System.FilePath.Posix

data MainCfg
  = MainCfg
      { useStdin :: Bool,
        argInput :: Maybe Text,
        configType :: SourceType
      }

commonParser :: Parser MainCfg
commonParser =
  MainCfg
    <$> flag
      False
      True
      (long "stdin" <> short 'i' <> help "Read configuration on stdin.")
    <*> optional
      ( strArgument
          ( metavar "CONFIG"
              <> help
                "Input configuration with .yml/.yaml/.dh/.dhall extension. Leave void for stdin (dhall) input."
          )
      )
    <*> flag
      Dhall
      Yaml
      ( long "yaml" <> short 'y'
          <> help
            "Assume configuration to be yaml(json is valid yaml) instead of dhall."
      )

opts :: Parser (IO Cfg)
opts = (load <$> commonParser) <**> helper

data SourceType = Dhall | Yaml | Json
  deriving (Eq)

data FinallySource = UseDefault | NoExt | FinallyFile SourceType Text | FinallyStdin SourceType

ext :: Bool -> SourceType -> Maybe Text -> FinallySource
ext _ _ (Just fn)
  | xt `elem` ([".dh", ".dhall"] :: IsString a => [a]) = FinallyFile Dhall fn
  | xt `elem` ([".yml", ".yaml"] :: IsString a => [a]) = FinallyFile Yaml fn
  | xt == ".json" = FinallyFile Json fn
  | otherwise = NoExt
  where
    xt = takeExtension $ toS fn
ext useStdin st Nothing = if useStdin then FinallyStdin st else UseDefault

load :: MainCfg -> IO Cfg
load MainCfg {..} =
  case ext useStdin configType argInput of
    UseDefault -> return def
    (FinallyFile sourceType filename) ->
      makeAbsolute (toS filename) >>= readFile >>= (process sourceType . toS)
    (FinallyStdin sourceType) ->
      B.getContents >>= process sourceType
    NoExt ->
      argInput & \case
        Nothing -> return def
        Just s -> process configType (toS s)
  where
    process = processType (Proxy :: Proxy Cfg)

processType ::
  (Default x, Dhall.Interpret x, Dhall.Inject x) =>
  Proxy x ->
  SourceType ->
  ByteString ->
  IO x
processType proxy@(Proxy :: Proxy x) sourceType bs =
  mergeAndExtract (def :: x) =<< toExpr proxy sourceType bs

toExpr ::
  (Dhall.Inject x, Dhall.Interpret x, Default x) =>
  Proxy x ->
  SourceType ->
  ByteString ->
  IO (Dhall.Expr Dhall.Src Void)
toExpr _proxy Dhall s = Dhall.inputExpr $ toS s
toExpr proxy Yaml s = sourceValueToExpr proxy $ Y.decodeEither' s
toExpr proxy Json s = sourceValueToExpr proxy $ J.eitherDecode' (toS s)

sourceValueToExpr ::
  (Default x, Dhall.Interpret x, Dhall.Inject x) =>
  Proxy x ->
  Either e Y.Value ->
  IO (Dhall.Expr Dhall.Src Void)
sourceValueToExpr (Proxy :: Proxy x) = \case
  Left _ -> die "yaml parsing exception"
  Right v ->
    DJ.dhallToJSON exprValue & \case
      Left e -> die $ "horrible internal dhall error in cli parsing: " <> show e
      Right jsonValue ->
        JSONToDhall.dhallFromJSON
          JSONToDhall.defaultConversion
          exprType
          (lodashMerge jsonValue v)
          & \case
            Left e -> die ("yaml -> dhall compilation error" <> show e)
            Right expr -> return expr
  where
    exprType :: Dhall.Expr Dhall.Src Void
    exprType = typeToExpr (Proxy :: Proxy x)
    exprValue = valueToExpr (def :: x)

mergeAndExtract ::
  (Dhall.Interpret x, Dhall.Inject x) =>
  x ->
  Dhall.Expr Dhall.Src Void ->
  IO x
mergeAndExtract x expr =
  Dhall.extract
    Dhall.auto
    ( Dhall.normalize
        ( Dhall.Prefer
            (valueToExpr x)
            expr
        )
    )
    & \case
      V.Failure _ -> die "dhall extraction error"
      V.Success a -> return a
