module dc_ipu_test;

localparam SCR_SIZE_WIDTH = 12;
localparam TEX_SIZE_WIDTH = 12;

reg clk;
reg nreset;

reg ctl_valid;
wire ctl_ready;
reg[SCR_SIZE_WIDTH-1:0] ctl_image_offset_x;
reg[SCR_SIZE_WIDTH-1:0] ctl_image_offset_y;
reg[SCR_SIZE_WIDTH-1:0] ctl_image_width;
reg[SCR_SIZE_WIDTH-1:0] ctl_image_height;
reg[SCR_SIZE_WIDTH-1:0] ctl_screen_width;
reg[SCR_SIZE_WIDTH-1:0] ctl_screen_height;
reg[SCR_SIZE_WIDTH-1:0] ctl_screen_y;
reg[TEX_SIZE_WIDTH-1:0] ctl_tex_width;
reg[TEX_SIZE_WIDTH-1:0] ctl_tex_height;
reg[1:0] ctl_scale_method;
reg[23:0] ctl_border_color;

wire tex_request_valid;
reg tex_request_ready;
wire[TEX_SIZE_WIDTH-1:0] tex_request_y;

reg texel_valid;
wire texel_ready;
reg[23:0] texel_data0;
reg[23:0] texel_data1;
reg[23:0] texel_data2;
reg[23:0] texel_data3;

wire pixel_valid;
reg pixel_ready;
wire[23:0] pixel_data;
wire pixel_border;

wire status_done;

dc_image_processing_unit #(
  .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .TEX_SIZE_WIDTH(TEX_SIZE_WIDTH)
)
u_ipu(
  .clk(clk),
  .nreset(nreset),

  .status_done(status_done),

  .ctl_valid(ctl_valid),
  .ctl_ready(ctl_ready),
  .ctl_image_offset_x(ctl_image_offset_x),
  .ctl_image_offset_y(ctl_image_offset_y),
  .ctl_image_width(ctl_image_width),
  .ctl_image_height(ctl_image_height),
  .ctl_screen_width(ctl_screen_width),
  .ctl_screen_y(ctl_screen_y),
  .ctl_tex_width(ctl_tex_width),
  .ctl_tex_height(ctl_tex_height),
  .ctl_scale_method(ctl_scale_method),
  .ctl_border_color(ctl_border_color),
  
  .tex_request_valid(tex_request_valid),
  .tex_request_ready(tex_request_ready),
  .tex_request_y(tex_request_y),
  
  .texel_valid(texel_valid),
  .texel_ready(texel_ready),
  .texel_data0(texel_data0),
  .texel_data1(texel_data1),
  .texel_data2(texel_data2),
  .texel_data3(texel_data3),

  .pixel_valid(pixel_valid),
  .pixel_ready(pixel_ready),
  .pixel_data(pixel_data),
  .pixel_border(pixel_border)
);


initial begin
  ctl_image_offset_x = 12'd3;
  ctl_image_offset_y = 12'd1;
  ctl_image_width = 12'd12;
  ctl_image_height = 12'd12;
  ctl_screen_width = 12'd32;
  ctl_screen_height = 12'd32;
  ctl_screen_y = 12'd0;
  ctl_tex_width = 12'd8;
  ctl_tex_height = 12'd8;
  ctl_scale_method = 2'd0;
  ctl_border_color = 24'hCAFFEE;
  ctl_valid = 1'b0;

  texel_data0 = 24'hC0;
  texel_data1 = 24'hA0;
  texel_data2 = 24'hF0;
  texel_data3 = 24'hE0;
  texel_valid = 1'b1;

  tex_request_ready = 1'b0;
  pixel_ready = 1'b1;
  
  clk = 0;
  nreset = 0;
  #1;
  clk = 1;
  #1;
  nreset = 1;
  #1;
  clk = 0;

  ctl_valid = 1;

  for (int i = 0; i < 4096; i++) begin
    #1;
    clk = 1;

    if (status_done)
      ctl_screen_y = ctl_screen_y + 1;

    if (tex_request_valid)
      tex_request_ready = 1;

    if (texel_ready && texel_valid) begin
      texel_data0 = texel_data0 + 1;
      texel_data1 = texel_data1 + 1;
      texel_data2 = texel_data2 + 1;
      texel_data3 = texel_data3 + 1;
    end

    #1;
    clk = 0;
  end

end

endmodule
