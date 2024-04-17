module dc_main_control_logic #(
  parameter LINE_NUMBER_WIDTH,
  parameter AXI_ARADDR_WIDTH,
  parameter TEX_SIZE_WIDTH,
  parameter RGB_WIDTH,
  parameter SCALE_METHOD_WIDTH,
  parameter SCR_SIZE_WIDTH,
  parameter PIXELS_PER_LINE_WIDTH
)(
  input wire clk,
  input wire nrst,
  input wire en,

  input wire sw_test_en,
  input wire[2:0] sw_layer_0_pos,
  input wire[2:0] sw_layer_0_scaling,
  input wire[1:0] sw_scaling_method,  // sw inputs are connected to switches on board
  input wire[(SCR_SIZE_WIDTH-1):0] const_input_size_width,
  input wire[(SCR_SIZE_WIDTH-1):0] const_input_size_height,  // input image dims
  input wire[(SCR_SIZE_WIDTH-1):0] const_output_size_height,
  input wire[(SCR_SIZE_WIDTH-1):0] const_output_size_width,  // display dim, height unused 
  input wire[(AXI_ARADDR_WIDTH-1):0] const_initial_address,
  input wire[(RGB_WIDTH-1):0] const_border_color,
  output wire led_frame_underrun,
  output wire led_frame_finished, 
  input wire user_int_valid,
  output wire user_int_ready,

  // IPU texture interface
  input wire tex_request_valid,
  output wire tex_request_ready,
  input wire[(TEX_SIZE_WIDTH-1):0] tex_request_y,

  // IPU control interface
  output wire ctl_valid,
  input wire ctl_ready,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_screen_y,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_x,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_y,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_width,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_height,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_screen_width,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_tex_width,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_tex_height,
  output wire[(SCALE_METHOD_WIDTH-1):0] ctl_scale_method,
  output wire[(RGB_WIDTH-1):0] ctl_border_color,
  input wire status_done,
  
  // FU interface
  output wire[(LINE_NUMBER_WIDTH-1):0] line_number, 
  output wire line_data_valid,
  input wire line_data_ready,
  output wire[(AXI_ARADDR_WIDTH-1):0] frame_addr,
  output wire[(PIXELS_PER_LINE_WIDTH-1):0] pixels_per_line,
  
  // BU interface
  output wire next_line,
  output wire no_func_switch,
  output wire output_en,

  //VU interface
  input wire vertical_blanking,
  input wire horizontal_blanking
);

wire[(SCR_SIZE_WIDTH-1):0] conf_image_offset_x;
wire[(SCR_SIZE_WIDTH-1):0] conf_image_offset_y;
wire[(SCR_SIZE_WIDTH-1):0] conf_image_width;
wire[(SCR_SIZE_WIDTH-1):0] conf_image_height;
wire[(SCR_SIZE_WIDTH-1):0] conf_screen_width;
wire[(SCR_SIZE_WIDTH-1):0] conf_screen_height;
wire[(SCR_SIZE_WIDTH-1):0] conf_tex_width;
wire[(SCR_SIZE_WIDTH-1):0] conf_tex_height;
wire[(SCALE_METHOD_WIDTH-1):0] conf_scale_method;
wire[(RGB_WIDTH-1):0] conf_border_color;
wire[(AXI_ARADDR_WIDTH-1):0] conf_tex_address;
wire underrun;
wire frame_finished;
wire conf_valid;
wire conf_ready;

dc_mcl_config_manager #(
  .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .AXI_ARADDR_WIDTH(AXI_ARADDR_WIDTH),
  .RGB_WIDTH(RGB_WIDTH),
  .SCALE_METHOD_WIDTH(SCALE_METHOD_WIDTH)
) config_manager(
  .clk(clk),
  .nrst(nrst),
  .en(en),

  .sw_test_en(sw_test_en),
  .sw_layer_0_pos(sw_layer_0_pos),
  .sw_layer_0_scaling(sw_layer_0_scaling),
  .sw_scaling_method(sw_scaling_method),  // sw inputs are connected to switches on board
  .const_input_size_width(const_input_size_width),
  .const_input_size_height(const_input_size_height),  // input image dims
  .const_output_size_width(const_output_size_width),
  .const_output_size_height(const_output_size_height),  // display dims
  .const_initial_address(const_initial_address),
  .const_border_color(const_border_color),
  .led_frame_underrun(led_frame_underrun),
  .led_frame_finished(led_frame_finished),
  .user_int_valid(user_int_valid),
  .user_int_ready(user_int_ready),

  .conf_image_offset_x(conf_image_offset_x),
  .conf_image_offset_y(conf_image_offset_y),
  .conf_image_width(conf_image_width),
  .conf_image_height(conf_image_height),  // scaled image dims
  .conf_screen_width(conf_screen_width),
  .conf_screen_height(conf_screen_height),
  .conf_tex_width(conf_tex_width),
  .conf_tex_height(conf_tex_height),  // input image dims
  .conf_scale_method(conf_scale_method),
  .conf_border_color(conf_border_color),
  .conf_tex_address(conf_tex_address),
  .underrun(underrun),
  .frame_finished(frame_finished),
  .conf_valid(conf_valid),
  .conf_ready(conf_ready)
);

assign frame_addr = conf_tex_address;
assign pixels_per_line = conf_tex_width;

dc_mcl_lines_display_manager #(
  .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .SCALE_METHOD_WIDTH(SCALE_METHOD_WIDTH),
  .RGB_WIDTH(RGB_WIDTH)
)lines_display_manager(
  .clk(clk),
  .nrst(nrst),
  .en(en),
  
  // VU interface
  .vertical_blanking(vertical_blanking),
  .horizontal_blanking(horizontal_blanking),
  
  // config manager interface
  .conf_image_offset_x(conf_image_offset_x),
  .conf_image_offset_y(conf_image_offset_y),
  .conf_image_width(conf_image_width),
  .conf_image_height(conf_image_height),
  .conf_screen_width(conf_screen_width),
  .conf_screen_height(conf_screen_height),
  .conf_tex_width(conf_tex_width),
  .conf_tex_height(conf_tex_height),
  .conf_scale_method(conf_scale_method),
  .conf_border_color(conf_border_color),
  .underrun(underrun),
  .frame_finished(frame_finished),
  .conf_valid(conf_valid),
  .conf_ready(conf_ready),
  
  // IPU interface
  .ctl_valid(ctl_valid),
  .ctl_ready(ctl_ready),
  .ctl_screen_y(ctl_screen_y),
  .ctl_image_offset_x(ctl_image_offset_x),
  .ctl_image_offset_y(ctl_image_offset_y),
  .ctl_image_width(ctl_image_width),
  .ctl_image_height(ctl_image_height),
  .ctl_screen_width(ctl_screen_width),
  .ctl_tex_width(ctl_tex_width),
  .ctl_tex_height(ctl_tex_height),
  .ctl_scale_method(ctl_scale_method),
  .ctl_border_color(ctl_border_color),
  .status_done(status_done)
);

dc_mcl_texture_request_manager #(
  .TEX_SIZE_WIDTH(TEX_SIZE_WIDTH),
  .LINE_NUMBER_WIDTH(LINE_NUMBER_WIDTH)
)texture_request_manager(
  .clk(clk),
  .nrst(nrst),
  .en(en),

  .frame_finished(frame_finished),
  .conf_valid(conf_valid),
  
  //IPU interface
  .tex_request_valid(tex_request_valid),
  .tex_request_ready(tex_request_ready),
  .tex_request_y(tex_request_y),
  
  // FU interface
  .line_number(line_number), 
  .line_data_valid(line_data_valid),
  .line_data_ready(line_data_ready),
  
  // BU interface
  .next_line(next_line),
  .no_func_switch(no_func_switch),
  .output_en(output_en)
);

endmodule
