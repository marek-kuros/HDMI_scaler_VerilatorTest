# Pipelined unsigned integer division block

`dc_ipu_array_divider_seq` implements a configurable pipelined integer division unit.

|Parameter|Description|
|---------|-----------|
|`A_WIDTH`|Dividend width|
|`B_WIDTH`|Divisor width|

|Signal|Description|
|------|-----------|
|in `clk`|Clock|
|in `nreset`|Asynchronous reset (active low)|
|in `clr`|Synchronous clear signal (marks data as invalid)|
|in `in_valid`|Valid signal from previous block|
|out `in_ready`|Ready signal from previous block|
|out `out_valid`|Valid signal for the next block|
|in `out_ready`|Ready signal for the next block|
|in `a`|Dividend|
|in `b`|Divisor|
|out `q`|Quotient|
|out `r`|Remainder|