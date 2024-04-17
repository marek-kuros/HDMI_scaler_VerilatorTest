`timescale 1 ns/1 ps

module dc_toplevel#(
  parameter AXI_ARADDR_WIDTH = 32,
  parameter PIXELS_PER_LINE_WIDTH = 12,
  parameter LINE_NUMBER_WIDTH = 12,
  parameter READ_DATA_SIZE = 1,
  parameter FETCH_WORD_COUNT_WIDTH = 16,
  parameter BUFFER_SIZE = 128,
  parameter BUFF_ADDR_WIDTH = 7,
  parameter BUFFER_NUM = 5,
  parameter SCR_SIZE_WIDTH = 12,
  parameter BITS_PER_PIXEL = 24,
  parameter SCALE_METHOD_WIDTH = 2
)(
  clk,
  en,
  nrst,

  // input/soutputs connected to FPGA switches and leds 
  sw_test_en,
  sw_layer_0_pos,
  sw_layer_0_scaling,
  sw_scaling_method,  // sw inputs are connected to switches on board
  const_input_size_width,
  const_input_size_height,  // input image dims
  const_output_size_width,
  const_output_size_height,  // display dims
  const_initial_address,
  const_border_color,
  led_frame_underrun,
  led_frame_finished,
  user_int_valid,
  user_int_ready,

  // VU interfce
  vertical_blanking,
  horizontal_blanking,
  ipu_pixel_valid,
  ipu_pixel_ready,
  ipu_pixel_data,
  ipu_pixel_border,
  
  //added data
  input_color_data
  

  // AXI read address
//  axi_arid,    
//  axi_araddr,  
//  axi_arlen,   
//  axi_arsize,  
//  axi_arburst, 
//  axi_arlock,  
//  axi_arcache, 
//  axi_arprot,  
//  axi_arqos,   
//  axi_arregion,
//  axi_arvalid, 
//  axi_arready, 
//
//  // AXI read data
//  axi_rid,   
//  axi_rdata, 
//  axi_rresp, 
//  axi_rlast, 
//  axi_rvalid,
//  axi_rready
);
  localparam IPU_TEX_SIZE_WIDTH = 12;

  input wire clk;
  input wire en;
  input wire nrst;
  
  // input/soutputs connected to FPGA switches and leds 
  input wire sw_test_en;
  input wire[2:0] sw_layer_0_pos;
  input wire[2:0] sw_layer_0_scaling;
  input wire[1:0] sw_scaling_method;  // sw inputs are connected to switches on board
  input wire[(SCR_SIZE_WIDTH-1):0] const_input_size_width;
  input wire[(SCR_SIZE_WIDTH-1):0] const_input_size_height;  // input image dims
  input wire[(SCR_SIZE_WIDTH-1):0] const_output_size_width;
  input wire[(SCR_SIZE_WIDTH-1):0] const_output_size_height;  // display dims
  input wire[(AXI_ARADDR_WIDTH-1):0] const_initial_address;
  input wire[(BITS_PER_PIXEL-1):0] const_border_color;
  output wire led_frame_underrun;
  output wire led_frame_finished;
  input wire user_int_valid;
  output wire user_int_ready;
  
  //hdmi bypass signal
  input wire [BITS_PER_PIXEL-1:0] input_color_data;
  
  // VU interfce
  input wire vertical_blanking;
  input wire horizontal_blanking;
  output wire ipu_pixel_valid;
  input wire ipu_pixel_ready;
  output wire[(BITS_PER_PIXEL-1):0] ipu_pixel_data;
  output wire ipu_pixel_border;

  // AXI read address
//  output wire[7:0] axi_arid;    
//  output wire[(AXI_ARADDR_WIDTH-1):0] axi_araddr;  
//  output wire[7:0] axi_arlen;   
//  output wire[2:0] axi_arsize;  
//  output wire[1:0] axi_arburst; 
//  output wire[1:0] axi_arlock;  
//  output wire[3:0] axi_arcache; 
//  output wire[2:0] axi_arprot;  
//  output wire[3:0] axi_arqos;   
//  output wire[3:0] axi_arregion;
//  output wire axi_arvalid; 
//  input wire axi_arready; 
//
//  // AXI read data
//  input wire[7:0] axi_rid;   
//  input wire[15:0] axi_rdata; 
//  input wire[1:0] axi_rresp; 
//  input wire axi_rlast; 
//  input wire axi_rvalid;
//  output wire axi_rready;



wire[(AXI_ARADDR_WIDTH-1):0] frame_addr;
wire[(PIXELS_PER_LINE_WIDTH-1):0] pixels_per_line;
wire[(LINE_NUMBER_WIDTH-1):0] line_number;
wire line_data_valid;
wire line_data_ready;

wire[(BITS_PER_PIXEL-1):0] pixel_data;
wire pixel_fifo_en;

//dc_fetching_unit #(
//  .AXI_ARADDR_WIDTH(AXI_ARADDR_WIDTH),
//  .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH),
//  .LINE_NUMBER_WIDTH(LINE_NUMBER_WIDTH),
//  .READ_DATA_SIZE(READ_DATA_SIZE),
//  .FETCH_WORD_COUNT_WIDTH(FETCH_WORD_COUNT_WIDTH),
//  .BITS_PER_PIXEL(BITS_PER_PIXEL)
//)fetching_unit(
//  .clk(clk),
//  .en(en),
//  .nrst(nrst),
//
//  .frame_addr(frame_addr),
//  .pixels_per_line(pixels_per_line),
//  .line_number(line_number), 
//  .line_data_valid(line_data_valid),
//  .line_data_ready(line_data_ready),
//
//  .axi_arid(axi_arid),  
//  .axi_araddr(axi_araddr),  
//  .axi_arlen(axi_arlen),   
//  .axi_arsize(axi_arsize),  
//  .axi_arburst(axi_arburst), 
//  .axi_arlock(axi_arlock),  
//  .axi_arcache(axi_arcache), 
//  .axi_arprot(axi_arprot),  
//  .axi_arqos(axi_arqos),   
//  .axi_arregion(axi_arregion),
//  .axi_arvalid(axi_arvalid),
//  .axi_arready(axi_arready), 
//
//  .axi_rid(axi_rid),   
//  .axi_rdata(axi_rdata), 
//  .axi_rresp(axi_rresp), 
//  .axi_rlast(axi_rlast), 
//  .axi_rvalid(axi_rvalid),
//  .axi_rready(axi_rready), 
//
//  .pixel_data(pixel_data),
//  .pixel_fifo_en(pixel_fifo_en)
//);

wire reset_x;
wire next_line;
wire no_func_switch;
wire output_en;
assign reset_x = '0;

wire[(BITS_PER_PIXEL-1):0] pixel_data_y0;
wire[(BITS_PER_PIXEL-1):0] pixel_data_y1;
wire[(BITS_PER_PIXEL-1):0] pixel_data_y2;
wire[(BITS_PER_PIXEL-1):0] pixel_data_y3;
wire pixel_data_valid;
reg pixel_data_ready;

//dc_buffering_unit #(
//  .BUFFER_SIZE(BUFFER_SIZE),
//  .BUFF_ADDR_WIDTH(BUFF_ADDR_WIDTH),
//  .BUFFER_NUM(BUFFER_NUM),
//  .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH),
//  .BITS_PER_PIXEL(BITS_PER_PIXEL)
//)buffering_unit(
//  .clk(clk),
//  .en(en),
//  .nrst(nrst),
//  
//  .pixels_per_line(pixels_per_line),
//  .pixel_data(pixel_data),
//  .pixel_fifo_en(pixel_fifo_en),
//
//  .reset_x(reset_x),
//  .next_line(next_line),
//  .no_func_switch(no_func_switch),
//  .output_en(output_en),
//
//  .pixel_data_y0(pixel_data_y0),
//  .pixel_data_y1(pixel_data_y1),
//  .pixel_data_y2(pixel_data_y2),
//  .pixel_data_y3(pixel_data_y3),
//  .pixel_data_valid(pixel_data_valid),
//  .pixel_data_ready(pixel_data_ready)
//);

wire ipu_status_done;

wire ipu_ctl_valid;
wire ipu_ctl_ready;
wire[SCR_SIZE_WIDTH-1:0] ipu_ctl_image_offset_x;
wire[SCR_SIZE_WIDTH-1:0] ipu_ctl_image_offset_y;
wire[SCR_SIZE_WIDTH-1:0] ipu_ctl_image_width;
wire[SCR_SIZE_WIDTH-1:0] ipu_ctl_image_height;
wire[SCR_SIZE_WIDTH-1:0] ipu_ctl_screen_width;
wire[SCR_SIZE_WIDTH-1:0] ipu_ctl_screen_y;
wire[IPU_TEX_SIZE_WIDTH-1:0] ipu_ctl_tex_width;
wire[IPU_TEX_SIZE_WIDTH-1:0] ipu_ctl_tex_height;
wire[(SCALE_METHOD_WIDTH-1):0] ipu_ctl_scale_method;
wire[BITS_PER_PIXEL-1:0] ipu_ctl_border_color;

wire ipu_tex_request_valid;
wire ipu_tex_request_ready;
wire[IPU_TEX_SIZE_WIDTH-1:0] ipu_tex_request_y;

wire ipu_texel_valid;
wire ipu_texel_ready;
wire[BITS_PER_PIXEL-1:0] ipu_texel_data0;
wire[BITS_PER_PIXEL-1:0] ipu_texel_data1;
wire[BITS_PER_PIXEL-1:0] ipu_texel_data2;
wire[BITS_PER_PIXEL-1:0] ipu_texel_data3;

// TODO: find a nice way to propagate consts like SCALE_METHOD_WIDTH from IPU? Maybe the constants file?
dc_image_processing_unit #(
  .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .TEX_SIZE_WIDTH(IPU_TEX_SIZE_WIDTH)
)
u_ipu(
  .clk(clk),
  .nreset(nrst),

  .status_done(ipu_status_done),

  .ctl_valid(ipu_ctl_valid),
  .ctl_ready(ipu_ctl_ready),
  .ctl_image_offset_x(ipu_ctl_image_offset_x),
  .ctl_image_offset_y(ipu_ctl_image_offset_y),
  .ctl_image_width(ipu_ctl_image_width),
  .ctl_image_height(ipu_ctl_image_height),
  .ctl_screen_width(ipu_ctl_screen_width),
  .ctl_screen_y(ipu_ctl_screen_y),
  .ctl_tex_width(ipu_ctl_tex_width),
  .ctl_tex_height(ipu_ctl_tex_height),
  .ctl_scale_method(ipu_ctl_scale_method),
  .ctl_border_color(ipu_ctl_border_color),
  
  .tex_request_valid(ipu_tex_request_valid),
  .tex_request_ready(ipu_tex_request_ready),
  .tex_request_y(ipu_tex_request_y),
  
  .texel_valid(pixel_data_valid),
  .texel_ready(pixel_data_ready),
  .texel_data0(input_color_data),
  .texel_data1(input_color_data),
  .texel_data2(input_color_data),
  .texel_data3(input_color_data),

  .pixel_valid(ipu_pixel_valid),
  .pixel_ready(ipu_pixel_ready),
  .pixel_data(ipu_pixel_data),
  .pixel_border(ipu_pixel_border)
);

dc_main_control_logic #(
  .LINE_NUMBER_WIDTH(LINE_NUMBER_WIDTH),
  .AXI_ARADDR_WIDTH(AXI_ARADDR_WIDTH),
  .TEX_SIZE_WIDTH(IPU_TEX_SIZE_WIDTH),
  .RGB_WIDTH(BITS_PER_PIXEL),
  .SCALE_METHOD_WIDTH(SCALE_METHOD_WIDTH),
  .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH)
)mcl(
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

  // IPU texture interface
  .tex_request_valid(ipu_tex_request_valid),
  .tex_request_ready(ipu_tex_request_ready),
  .tex_request_y(ipu_tex_request_y),

  // IPU control interface
  .ctl_valid(ipu_ctl_valid),
  .ctl_ready(ipu_ctl_ready),
  .ctl_screen_y(ipu_ctl_screen_y),
  .ctl_image_offset_x(ipu_ctl_image_offset_x),
  .ctl_image_offset_y(ipu_ctl_image_offset_y),
  .ctl_image_width(ipu_ctl_image_width),
  .ctl_image_height(ipu_ctl_image_height),
  .ctl_screen_width(ipu_ctl_screen_width),
  .ctl_tex_width(ipu_ctl_tex_width),
  .ctl_tex_height(ipu_ctl_tex_height),
  .ctl_scale_method(ipu_ctl_scale_method),
  .ctl_border_color(ipu_ctl_border_color),
  .status_done(ipu_status_done),
  
  // FU interface
  .line_number(line_number),
  .line_data_valid(line_data_valid),
  .line_data_ready(line_data_ready),
  .frame_addr(frame_addr),
  .pixels_per_line(pixels_per_line),
  
  // BU interface
  .next_line(next_line),
  .no_func_switch(no_func_switch),
  .output_en(output_en),

  //VU interface
  .vertical_blanking(vertical_blanking),
  .horizontal_blanking(horizontal_blanking)
);

//dumpers 
/*
dc_dumper_ipu #(
                .IMG_HEIGHT(480),
                .IMG_WIDTH(640)
                )
dumper_ipu      
              (
                .clk(clk),
                .nrst(nrst),
                .pixel_valid(ipu_pixel_valid),
                .pixel_ready(ipu_pixel_ready),
                .pixel_data(ipu_pixel_data)
);

dc_dumper_fetching_unit #(
                          .IMG_WIDTH(128),
                          .IMG_HEIGHT(128),
                          .LINE_NUMBER_WIDTH(LINE_NUMBER_WIDTH))
dumper_fu                (
                          .clk(clk),
                          .nrst(nrst),
                          .line_number(line_number),
                          .line_data_valid(line_data_valid),
                          .line_data_ready(line_data_ready),
                          .pixel_data(pixel_data),
                          .pixel_fifo_en(pixel_fifo_en)

);
*/

endmodule
