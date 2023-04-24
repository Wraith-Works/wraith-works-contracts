#!/bin/sh

rm -rf artifacts build cache node_modules

yarn install
yarn compile

mkdir -p build/contracts
find artifacts/contracts/ -name "*.json" -exec cp {} build/contracts/ \;
rm build/contracts/*.dbg.json