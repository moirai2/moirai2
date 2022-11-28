#!/bin/sh

docker-compose up -d
sleep 5
open http://localhost:5000/moirai2/
