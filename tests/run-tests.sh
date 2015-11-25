#!/bin/bash

# first build the test container
docker build -t ssh2-scp-tests .

# then execute it to run the tests
printf '\n\n   Tests:\n\n'
docker run -t ssh2-scp-tests
