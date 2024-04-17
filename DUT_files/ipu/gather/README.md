# Texel Gather Block

`dc_ipu_gather` implements a 4x4 texel quad gathering block. Operation is initiated by
asserting the `ctl_start` signal while `ctl_clamp_y` and `ctl_tex_width` contain valid data.
In subsequent clock cycles, first portion of data is prefetched from the `texel_*` interface.

The `tc_ready` signal indicates that the block is ready to accept texture coordinates on the `tc_*`
interface. Ideally, values of `tc_int` should be subsequent integers.

|Parameter|Description|
|---------|-----------|
|`TEX_SIZE_WIDTH`|Texture size width|
|`TEX_FRACT_WIDTH`|Texture interpolation coefficient width|
|`COLOR_WIDTH`|Color bit-depth|

|Signal|Description|
|------|-----------|
|in `clk`|Clock|
|in `nreset`|Asynchronous reset (active low)|
|in `ctl_start`|Initializes processing of a texture line|
|in `ctl_abort`|Terminates processing (only when active)|
|in `ctl_clamp_y`|Specifies clamping mode in the Y axis|
|in `ctl_tex_width`|Texture width|
|in `texel_valid`|Indicates valid texel data on the BU interface|
|out `texel_ready`|Indicates readiness to accept texel data from the BU|
|in `texel_data`|Texel data from BU|
|in `tc_valid`|Indicates valid texture coordinates on the interface|
|in `tc_ready`|Indicates readiness to accept texture coordinates|
|in `tc_int`|Intergral part of the texture X coordinate|
|in `tc_fract`|Fractional part of the texture X coordinate (interpolation coefficient)|
|out `quad_valid`|Indicates that the texel quad (and interpolation coefficient) on the output are valid|
|in `quad_ready`|Indicates that the next stage is ready to accept the data|
|out `quad_data`|4x4 texel quad data|
|out `quad_fract`|Fractional texture coordinate (synchronized with texel data)|
