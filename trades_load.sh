#!/bin/bash
#
# SciDB Examples using NYSE TAQ daily trades data
#
NARGS="$#"
if [ $NARGS -lt 2 ]; then
  echo "Usage: ./trades_load     path-to-trades-data    num-records"
  echo "Using defaults"
  FILEPATH="/tmp/EQY_US_ALL_TRADE_20131218.zip"
  NUMLINES=0 
  echo $FILEPATH
  echo $NUMLINES
else
  FILEPATH=$1
  NUMLINES=$2
fi

/opt/scidb/15.12/bin/iquery -aq "load_library('accelerated_io_tools')" 2>/dev/null

# We obtain one day of NYSE TAQ trades with (uncomment to download):
# wget ftp://ftp.nyxdata.com/Historical%20Data%20Samples/Daily%20TAQ/EQY_US_ALL_TRADE_20131218.zip
# The sample trades cover the consolidated US exchanges for one day at
# millisecond resolution.

# We remove in advance the arrays we'll create below. The 2>/dev/null part
# supresses printing of errors (for example if the array doesn't exist).
/opt/scidb/15.12/bin/iquery -naq "remove(trades_flat)" 2>/dev/null
/opt/scidb/15.12/bin/iquery -naq "remove(tkr)" 2>/dev/null
/opt/scidb/15.12/bin/iquery -naq "remove(minute_bars)" 2>/dev/null

# The raw trade data in the TAQ file is presented in fixed-width ASCII fields.
# Let's parse each raw data trade line into distinct values, storing
# the result into a 1-d SciDB array named 'trades_flat'. Note that
# we're only parsing out a few interesting fields from the raw data.
# We could easily parse more.
rm -f /tmp/pipe
mkfifo /tmp/pipe
if [ $NUMLINES -eq 0 ] 
then 
  zcat $FILEPATH | tail -n +2  > /tmp/pipe &
else
  zcat $FILEPATH |  head -n $NUMLINES | tail -n +2  > /tmp/pipe &
fi
  
/opt/scidb/15.12/bin/iquery  -naq "
store(
  project(
    apply( aio_input('/tmp/pipe', 'num_attributes=1'),
                tm, int64(substr(a0,0,2))*60*60000 +
                    int64(substr(a0,2,2))*60000 +
                    int64(substr(a0,4,2))*1000 +
                    int64(substr(a0,6,3)),
                exchange, substr(a0,9,1),
                symbol, trim(substr(a0,10,16)),
                condition, trim(substr(a0,26,4)),
                volume, int64(substr(a0,30,9)),
                price, double(substr(a0,39,7)) +
                       double(substr(a0,46,4))/10000,
                sequence_number, int64(substr(a0,53,16))
    ), tm, symbol, volume, price, exchange, condition, sequence_number),
  trades_flat)"
