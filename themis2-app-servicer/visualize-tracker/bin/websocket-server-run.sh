#!/bin/bash

timeout 30 bash <<EOS
sleep 5
until curl -sf http://localhost:3000/api/initialize-server; do
  sleep 5
done
EOS