#!/bin/bash

rm -rf toc-trade-protobuf
git clone git@github.com:ToC-Taiwan/toc-trade-protobuf.git

rm -rf lib/pb
mkdir lib/pb

protoc --proto_path=./toc-trade-protobuf --dart_out=./lib/pb ./toc-trade-protobuf/app.proto
rm -rf toc-trade-protobuf
git add lib/pb
