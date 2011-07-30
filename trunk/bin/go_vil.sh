#!/bin/sh


VIL=$1
NUM=$2


ruby bin/addpl_n.rb $VIL $NUM
ruby bin/update_phase.rb $VIL g
ruby bin/update_phase.rb $VIL d
ruby bin/update_phase.rb $VIL o
ruby bin/update_phase.rb $VIL n
ruby bin/update_phase.rb $VIL d
ruby bin/update_phase.rb $VIL v
ruby bin/update_phase.rb $VIL o
ruby bin/update_phase.rb $VIL n
ruby bin/update_phase.rb $VIL g
echo 'end'