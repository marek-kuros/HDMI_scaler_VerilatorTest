# Reusable pipelining logic

`dc_ipu_shr_pipeline_buffer` and `dc_ipu_shr_pipeline_logic` implement reusable 
pipeline stage input buffer and control logic (`ready` signal buffering).

## Control logic interface

|Signal|Description|
|------|-----------|
|in `clk`|Clock|
|in `nreset`|Asynchronous reset (active low)|
|in `clr`|Synchronous clear signal (marks data as invalid)|
|in `en`|Stage-local enable signal (e.g. `ready` from the next stage)|
|out `valid`|Indicates whether the data in the buffers is valid|
|in `in_valid`|Valid signal from previous pipeline block|
|out `in_ready`|Ready signlal for previous pipeline block|
|out `buf_main_en`|Main buffer enable signal (connect to buffer units)|
|out `buf_side_en`|Side buffer enable signal (connect to buffer units)|
|out `buf_restore`|Side buffer restore signal (connecto to buffer units)|

## Buffer interface

|Parameter|Description|
|---------|-----------|
|`WIDTH`|Buffer width|

|Signal|Description|
|------|-----------|
|in `clk`|Clock|
|in `nreset`|Asynchronous reset (active low)|
|out `buf_main_en`|Main buffer enable signal|
|out `buf_side_en`|Side buffer enable signal|
|out `buf_restore`|Side buffer restore signal|
|in `d`|Data input|
|out `q`|Data output|