#!/usr/bin/env bats

SERVER_IP="172.17.42.1"

@test "transfer file to the server" {
  echo "Testfile" > test.txt
  run scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null test.txt $SERVER_IP:/test
  [ "$status" -eq 0 ]
}

@test "transfer file from the server" {
  run scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SERVER_IP:/some/path/file ./fileFromServer
  [ "$status" -eq 0 ]
  content=$(cat ./fileFromServer)
  [ "$content" == "You requested: /some/path/file" ]
}

@test "transfer directory to the server" {
  mkdir ./dir
  echo "Testfile1" > ./dir/test1.txt
  echo "Testfile2" > ./dir/test2.txt
  run scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dir $SERVER_IP:/test
  [ "$status" -eq 0 ]
}
