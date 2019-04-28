#!/bin/bash

HOST=10.0.0.68
FILENAME=supersweet.bin
REMOTE_FILENAME=fpga.bin

curl -X POST http://${HOST}/delete/${REMOTE_FILENAME}
curl -X POST --upload-file  ${FILENAME} http://${HOST}/upload/${REMOTE_FILENAME}
sleep 2
curl -X POST http://${HOST}/fpga/update
