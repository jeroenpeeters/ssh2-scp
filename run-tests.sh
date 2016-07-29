#!/bin/bash

docker kill ssh2-scp-examples 1>&- 2>&-
docker rm -v ssh2-scp-examples 1>&- 2>&-

set -e

docker build -t ssh2-scp-examples .
docker run -d --name ssh2-scp-examples ssh2-scp-examples

cd ./tests
# first build the test container
docker build -t ssh2-scp-tests .

sleep 1
# then execute it to run the tests
printf '\n\n   Tests:\n\n'
docker run -t --rm -e SERVER_IP=examples --name ssh2-scp-tests --link ssh2-scp-examples:examples  ssh2-scp-tests

docker kill ssh2-scp-examples 1>&- 2>&-
docker rm -v ssh2-scp-examples 1>&- 2>&-
