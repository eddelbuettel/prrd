#!/bin/bash

test -f $1 || exit 0

sqlite3 -column -header $1 "select * from results order by endtime desc limit 10"

