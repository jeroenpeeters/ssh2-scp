#!/usr/bin/env bats


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
  run scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r dir $SERVER_IP:/test
  [ "$status" -eq 0 ]
}

@test "transfer directory with multiple levels to the server" {
  mkdir ./dir2
  echo "Testfile1" > ./dir2/test1.txt
  echo "Testfile2" > ./dir2/test2.txt
  mkdir ./dir2/subdir1
  echo "Testfile1" > ./dir2/subdir1/test1.txt
  echo "Testfile2" > ./dir2/subdir1/test2.txt
  run scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r dir2 $SERVER_IP:/test
  [ "$status" -eq 0 ]
}
