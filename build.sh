#!/usr/bin/env bash
rm -f .ghc.env*
nix-build -A nrm --option extra-substituters http://129.114.24.212/serve --option trusted-public-keys example-nix-cache-1:HSwzbJmGDidTrax3Lvx1vMSvto04VN2O5cjfXAG9uz0=
