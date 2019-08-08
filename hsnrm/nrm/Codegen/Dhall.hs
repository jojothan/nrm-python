{-|
Module      : Codegen.Dhall
Copyright   : Copyright (c) 2018 Oliver Charles.
License     : MIT License.

MIT License

Copyright (c) 2018 Oliver Charles

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Various Dhall code generation related utilities adapted from dhall-to-cabal-meta.
-}
module Codegen.Dhall
  ( writeOutput
  , relativeTo
  , {-, importFile-}
    takeDirectory
  , getDefault
  )
where

import qualified Data.Text.Prettyprint.Doc as Pretty
import qualified Data.Text.Prettyprint.Doc.Render.Text as Pretty
import qualified Dhall.Core
{-import qualified Dhall.Lint as Lint-}
{-import qualified Dhall.Parser-}
import Protolude
{-import System.FilePath-}
{-( (<.>)-}
{-, (</>)-}
{-, dropTrailingPathSeparator-}
{-, normalise-}
{-, splitDirectories-}
{-, splitFileName-}
{-, takeDirectory-}
{-)-}
import System.FilePath
  ( dropTrailingPathSeparator
  , joinPath
  , normalise
  , splitDirectories
  , splitFileName
  , takeDirectory
  )
import qualified System.IO

writeOutput :: FilePath -> Dhall.Core.Expr s Dhall.Core.Import -> IO ()
writeOutput dest expr =
  System.IO.withFile dest System.IO.WriteMode $ \hnd -> do
    System.IO.hPutStrLn hnd
      "--This file is auto-generated by nrm. Do not modify."
    Pretty.renderIO
      hnd $
      Pretty.layoutSmart prettyOpts
        (Pretty.pretty expr)
    System.IO.hPutStr hnd "\n"

prettyOpts :: Pretty.LayoutOptions
prettyOpts =
  Pretty.defaultLayoutOptions
    { Pretty.layoutPageWidth = Pretty.AvailablePerLine 80 1.0
    }

relativeTo
  :: FilePath
  -- ^ The path to be relative to. Note that the final file-name is
  -- ignored: @foo/bar@ is relative to @foo/@, even if @foo/bar@ is
  -- a directory.
  -> FilePath
  -- ^ The path to relativise.
  -> FilePath
relativeTo =
  \(splitDirectories . dropTrailingPathSeparator . takeDirectory . normalise -> base) ->
    \(splitDirectories . normalise -> path) ->
      joinPath (go base path)
  where
    -- @normalise "."@ is @"."@, so we have to take care here with dots.
    go (a : as) (b : bs)
      | a == b = go as bs
      | a == "." = go as (b : bs)
      | b == "." = go (a : as) bs
      | otherwise = (".." <$ (a : as)) ++ (b : bs)
    go [] bs = bs
    go as [] = ".." <$ as

getDefault
  :: (Eq s)
  => KnownType
  -> Expr.Expr s Dhall.Core.Import
getDefault typ = withTypesImport expr
  where
    withTypesImport =
      Expr.Let (Expr.Binding "types" Nothing (Expr.Embed typesLoc) :| [])
    factorBuildInfo fields =
      let shared = Map.filter id (Map.intersectionWith (==) fields (buildInfoDefault resolve))
       in if | null shared ->
               Expr.RecordLit fields
             | null (Map.difference fields shared) ->
               resolve (PreludeDefault BuildInfo)
             | otherwise ->
               Expr.Prefer
                 (resolve (PreludeDefault BuildInfo))
                 (Expr.RecordLit (Map.difference fields shared))
