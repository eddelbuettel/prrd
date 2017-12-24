#!/bin/bash

test -f $1 || exit 0

cat <<EOF | sqlite3 $1
.mode column
.header on 
select * from results order by endtime limit 10
EOF
