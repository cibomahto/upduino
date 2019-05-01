#!/bin/bash

#HOST=10.0.0.68
HOST=$1
FILENAME=supersweet.bin
REMOTE_FILENAME=fpga.bin

echo Uploading to: ${HOST}

curl -X POST http://${HOST}/delete/${REMOTE_FILENAME}
curl -X POST --upload-file  ${FILENAME} http://${HOST}/upload/${REMOTE_FILENAME}
sleep 2
curl -X POST http://${HOST}/fpga/update
