#!/usr/bin/env bash
rm -f .ghc.env*
if [ -z "$IN_NIX_SHELL" ]
then
  nix-shell --run "runhaskell dev/shake.hs $*"
else
  runhaskell dev/shake.hs "$*"
fi
