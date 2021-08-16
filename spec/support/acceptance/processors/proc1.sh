#! /bin/bash

cat $1 > /tmp/proc1

echo 'stdoutstreamhere'

echo 'errorstreamhereagain' 1>&2

exit 20
