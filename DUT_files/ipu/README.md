# Overview

Image Processing Unit (IPU) performs 2D texture upscaling and positioning.

IPU processing is initiated by a request on the control interface. Processing cycle
includes requesting texture data from the surrounding logic, reading texture data and
outputting pixel data.

The resulting image can be resized and positioned in the screen space. It, however, 
must not cross screen boundaries. Dimensions of the image must be larger than the
dimensions of the texture. Currently, downscaling is not suported.

The IPU is designed to support different upscaling algorithms. The scaling method is specified
in the processing request. Currently, only nearest neighbor filtering is available.

The pixels surrounding the scaled image are reffered to as _border_. The color of the border
is specified in the processing request. IPU provides an output signal indicating that the current pixel is part of the border.
This can be useful when compositing outputs from multiple IPUs.

Graphical representation of scaling and translation:<br>
<img width=40% src=https://github.com/intel-sandbox/dszczygi.internship22/assets/6173262/1f24f4fb-f1e2-4ca4-9ea0-2c6c45976c7e />

# Principle of operation

IPU processing is line-based.

Once a request is made on the control interface, the IPU starts processing of the
requested screen line. Currently, there is no way to abort or interrupt the processing
before end of the line is reached. 

If the line being processed contains part of the scaled image, a request will be made
by the IPU on the texture data request interaface. Upon reception of such request, the surrounding
logic must prepare requested lines for transmission to the IPU via the texel interface.

After requesting the data, the IPU waits for data on the texel interface.
Upon completing `screen_width` transfers on the pixel data interface, the IPU goes
back to the idle state and becomes ready to accept another request on the control interface.
Before IPU becomes idle, `status_done` is asserted for one clock cycle to indicate end of processing.

The diagram below presents interactions between IPU and the surrounding logic:<br>
<img width=40% src=https://github.com/intel-sandbox/dszczygi.internship22/assets/6173262/becec85a-4db0-4fa6-9a1a-4088eacc0bd1 />

# Interfaces

IPU has four valid/ready-based interfaces and two common signals.

### Common singals

|Signal|Description|
|------|-----------|
|in `clk`|Clock|
|in `nreset`|Asynchronous reset (active low)|

### Control interface

Control interface is used to initiate processing of a screen line. 

The `status_done` is an always valid status signal. IPU asserts this signal for one clock cycle upon completing processing of the last request.

|Signal|Description|
|------|-----------|
|in `ctl_valid`|Data on the control interface is valid|
|out `ctl_ready`|Control interface ready to accept data|
|in `ctl_image_offset_x`, `ctl_image_offset_y`|Offset of the displayed image relative to the screen origin|
|in `ctl_image_width`, `ctl_image_height`|Scaled image size in screen pixels|
|in `ctl_screen_width`, `ctl_screen_height`|Dimensions of the screen in pixels|
|in `ctl_screen_y`|Line requested to be drawn|
|in `ctl_tex_width`, `ctl_tex_height`|Dimensions of the texture|
|in `ctl_scale_method`|Scaling method to be used|
|in `ctl_border_color`|Border color|
|out `status_done`|Status signal indicating that line processing has been completed|

### Texture data request interface

Texture data request interface is used by the IPU to request portions of the texture data from the logic surrounding IPU.
Following a transaction on this interface, the requested data must appear at the texel interface. If the line currently being drawn
does not contain a part of the image/texture, IPU may restrain from requesting texture data.

|Signal|Description|
|------|-----------|
|out `tex_request_valid`|Data on the texture data request interface is valid|
|in `tex_request_ready`|Ready to accept the request|
|out `tex_request_y`|Y coordinate of the first (out of 4) texture line requested|

### Texel interface

The texel interface is used for reading texture data by the IPU. `texel_data0...3` should provide texture data from 4 subsequent lines. `texel_data0` is the topmost line.

If the IPU did not request texture data, no texel data will be read during that processing cycle.

|Signal|Description|
|------|-----------|
|in `texel_valid`|Texel data on the interface is valid|
|out `texel_ready`|Interface is ready to accept data|
|in `texel_data0..3`|RGB8 texel data from 4 subsequent lines|

_Note: `texel_data0` is the topmost texture line._

### Pixel interface

Pixel interface outputs pixel data to a screen/composition pipeline.

|Signal|Description|
|------|-----------|
|out `pixel_valid`|Pixel data on the interface is valid|
|in `pixel_ready`|Ready to accept pixel data|
|out `pixel_data`|RGB8 pixel data|
|out `pixel_border`|Indicates whether the current pixel is part of the border or the image|