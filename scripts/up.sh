#!/bin/sh

docker-compose up &
sleep 5
open http://localhost:5000/
