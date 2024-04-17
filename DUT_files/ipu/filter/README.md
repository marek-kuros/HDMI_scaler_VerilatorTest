# Texture Filtering Block

|Parameter|Description|
|---------|-----------|
|`COEFF_WIDTH`|Width of the interpolation coefficient|
|`COLOR_WIDTH`|Color bit-depth|

|Signal|Description|
|------|-----------|
|in `clk`|Clock|
|in `nreset`|Asynchronous reset (active low)|
|in `clr`|Synchronous pipeline clear signal|
|in `scale_method`|Controls which scaling algorithm is used|
|in `in_valid`|Indicates that the input data is valid|
|out `in_ready`|Indicates readiness to accept new input data|
|in `texel_quad`|4x4 texel quad|
|in `coeff_x`|Interpolation coeff. in the X axis|
|in `coeff_y`|Interpolation coeff. in the Y axis|
|out `out_valid`|Indicates that output data is valid|
|in `out_ready`|Indicates that the next block is ready to accept pixel data|
|out `out_pixel`|Interpolated pixel data|

_Note: After chaning the scaling algorithm, the pipeline should be cleared with the `clr` signal_
