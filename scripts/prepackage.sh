#!/bin/sh

rm -rf artifacts cache node_modules publish

yarn install
yarn compile

mkdir -p publish/build/contracts
find artifacts/contracts/ -name "*.json" -exec cp {} publish/build/contracts/ \;
rm publish/build/contracts/*.dbg.json

cp -r contracts/* publish/
rm -rf publish/mocks
cp LICENSE publish/
cp README.md publish/