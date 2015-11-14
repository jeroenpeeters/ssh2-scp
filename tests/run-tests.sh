#!/bin/bash

docker build -t ssh2-scp-tests .
printf '\n\n   Tests:\n\n'
docker run -t ssh2-scp-tests
