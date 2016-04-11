#!/bin/bash

# We remove in advance the arrays we'll create below. The 2>/dev/null part
# supresses printing of errors (for example if the array doesn't exist).
/opt/scidb/15.12/bin/iquery -naq "remove(quotes)" 2>/dev/null

# Create an array dimensioned along three coordinate axes:
# synthetic, just to separate conflicts--more efficient than using sequence_number
# symbol_index
# time (in ms)
# We use the same symbol index here that we built from the trade data.
/opt/scidb/15.12/bin/iquery -naq "
store(
  redimension(
    index_lookup(quotes_flat as A,tkr, A.symbol, symbol_index),
    <ask_price:double null, ask_size:int64 null, bid_price:double null, bid_size:int64 null, sequence_number: int64 null, condition:string null, exchange: string null>
    [synthetic=0:999,1000,0, symbol_index=0:*,10,0, tm=0:86399999,86400000,0]),
  quotes
)" || exit 1

# Clean up
/opt/scidb/15.12/bin/iquery -aq "remove(quotes_flat)" 2>/dev/null
