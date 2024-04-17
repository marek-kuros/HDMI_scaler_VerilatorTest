# Address compute pipeline

Sampled texture coordinate is computed as follows:

$$n_t = \frac{N_t(2n_o + 1)}{2N_o} - \frac{1}{2}$$

where $n_o$ is the position in the output image, $N_o$ is the output image size and $N_t$ is the size of the texture.

Computation is divided into following stages:

1. Compute $N_t(2n + 1)$
2. Divide by $N_o$
3. Divide the result by two and subtract $\frac{1}{2}$. Split into integral and fractional parts.

|Parameter|Description|
|---------|-----------|
|`IMG_SIZE_WIDTH`|Output image size width|
|`TEX_SIZE_WIDTH`|Texture size width|
|`TEX_FRACT_WIDTH`|Texture interpolation coefficient width|

|Signal|Description|
|------|-----------|
|in `clk`|Clock|
|in `nreset`|Asynchronous reset (active low)|
|in `clr`|Synchronous pipeline clear signal|
|in `in_valid`|Input valid signal|
|out `in_ready`|Input ready signal|
|in `x`|Pixel position in the output image|
|in `img_size`|Output image size|
|in `tex_size`|Texture size|
|out `out_valid`|Output valid signal|
|in `out_ready`|Output ready signal|
|out `tex_addr`|Integral part of the texture coordinate|
|out `tex_addr_fract`|Fractional part of the texture coordinate|

