#!/usr/bin/env bats
SERVER_IP="172.17.42.1"
#scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null test.txt 172.17.42.1:/test

@test "transfer file to the server" {
  echo "Testfile" > test.txt
  run scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null test.txt $SERVER_IP:/test
  [ "$status" -eq 0 ]
}

@test "transfer file from the server" {
  run scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SERVER_IP:/test ./fileFromServer
  [ "$status" -eq 0 ]
  content=$(cat ./fileFromServer)
  [ "$content" == "Dit is een testje" ]
}

# @test "addition using dc" {
#   result="$(echo 2 2+p | dc)"
#   [ "$result" -eq 4 ]
# }
