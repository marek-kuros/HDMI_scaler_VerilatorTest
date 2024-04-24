module dc_buffering_unit #(
  parameter BUFFER_SIZE = 128,
  parameter BYTES_PER_PIXEL = 3,
  parameter BUFF_ADDR_WIDTH = 7,
  parameter BUFFER_NUM = 5,
  parameter PIXELS_PER_LINE_WIDTH,
  parameter BITS_PER_PIXEL
)(
  input wire clk,
  input wire en,
  input wire nrst,
  
  input wire[(PIXELS_PER_LINE_WIDTH-1):0] pixels_per_line,  // for reading
  input wire[(BITS_PER_PIXEL-1):0] pixel_data,
  input wire pixel_fifo_en,

  input wire reset_x,
  input wire next_line,
  input wire no_func_switch,
  input wire output_en,

  output wire[(BITS_PER_PIXEL-1):0] pixel_data_y0,
  output wire[(BITS_PER_PIXEL-1):0] pixel_data_y1,
  output wire[(BITS_PER_PIXEL-1):0] pixel_data_y2,
  output wire[(BITS_PER_PIXEL-1):0] pixel_data_y3,
  output wire pixel_data_valid,
  input wire pixel_data_ready
);

wire[(BUFFER_NUM-1):0] write_buffer_id;
wire[(BUFFER_NUM-1):0] y0_buff;
wire[(BUFFER_NUM-1):0] y1_buff;
wire[(BUFFER_NUM-1):0] y2_buff;
wire[(BUFFER_NUM-1):0] y3_buff;

wire[(BUFFER_NUM-1):0] we_vec;
wire[(BUFF_ADDR_WIDTH-1):0] write_addr;
wire[(BUFF_ADDR_WIDTH-1):0] read_addr;

wire[(BITS_PER_PIXEL-1):0] rdata_b0;
wire[(BITS_PER_PIXEL-1):0] rdata_b1;
wire[(BITS_PER_PIXEL-1):0] rdata_b2;
wire[(BITS_PER_PIXEL-1):0] rdata_b3;
wire[(BITS_PER_PIXEL-1):0] rdata_b4;

wire[(BUFFER_NUM-1):0] re_vec; 
wire last_read_pixel;

dc_bu_write_manger #(
  .BUFF_ADDR_WIDTH(BUFF_ADDR_WIDTH),
  .BUFFER_SIZE(BUFFER_SIZE),
  .BUFFER_NUM(BUFFER_NUM),
  .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH)
)write_manger(
  .clk(clk), 
  .en(en),
  .nrst(nrst),
  
  .pixels_per_line(pixels_per_line),
  .pixel_fifo_en(pixel_fifo_en),

  .next_line(next_line),
  .write_buffer_id(write_buffer_id), 

  .mem_addr(write_addr),
  .we_vec(we_vec)
);

dc_bu_read_manger #(
  .BUFF_ADDR_WIDTH(BUFF_ADDR_WIDTH),
  .BUFFER_SIZE(BUFFER_SIZE),
  .BUFFER_NUM(BUFFER_NUM),
  .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH)
)read_manger(
  .clk(clk), 
  .en(en),
  .nrst(nrst),

  .pixels_per_line(pixels_per_line),
  .pixel_data_ready(pixel_data_ready),
  .next_line(next_line),
  .reset_x(reset_x),

  .write_buffer_id(write_buffer_id), 

  .mem_addr(read_addr),
  .re_vec(re_vec),
  .last_pixel(last_read_pixel)
);

dc_bu_buff_func_manager #(
  .BUFFER_NUM(BUFFER_NUM) 
)func_manager(
  .clk(clk),
  .en(en),
  .nrst(nrst),  

  .next_line(next_line),
  .no_func_switch(no_func_switch),
  .write_buff(write_buffer_id),
  .y0_buff(y0_buff),
  .y1_buff(y1_buff),
  .y2_buff(y2_buff),
  .y3_buff(y3_buff)
);

dc_bu_memory_cluster #(
  .BUFFER_SIZE(BUFFER_SIZE),
  .BITS_PER_PIXEL(BITS_PER_PIXEL),
  .BUFF_ADDR_WIDTH(BUFF_ADDR_WIDTH),
  .BUFFER_NUM(BUFFER_NUM) 
)memory_cluster(
  .clk(clk),
  .en(en),
  .nrst(nrst),

  .write_buff_en(we_vec),
  .write_addr(write_addr),
  .pixel_data(pixel_data),

  .read_buff_en(re_vec),
  .read_addr(read_addr),
  .rdata_b0(rdata_b0),
  .rdata_b1(rdata_b1),
  .rdata_b2(rdata_b2),
  .rdata_b3(rdata_b3),
  .rdata_b4(rdata_b4),
  .new_data(new_data)
);

dc_bu_lines_ordering #(
  .BITS_PER_PIXEL(BITS_PER_PIXEL),
  .BUFFER_NUM(BUFFER_NUM),
  .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH)
)lines_ordering(
  .clk(clk),
  .en(en),
  .nrst(nrst),

  .output_en(output_en),
  .last_read_pixel(last_read_pixel),
  .pixels_per_line(pixels_per_line),
  .next_line(next_line),

  .b0(rdata_b0),
  .b1(rdata_b1),
  .b2(rdata_b2),
  .b3(rdata_b3),
  .b4(rdata_b4),
  .new_data(new_data),

  .y0_buff(y0_buff),
  .y1_buff(y1_buff),
  .y2_buff(y2_buff),
  .y3_buff(y3_buff),

  .y0(pixel_data_y0),
  .y1(pixel_data_y1),
  .y2(pixel_data_y2),
  .y3(pixel_data_y3),
  .pixel_data_valid(pixel_data_valid),
  .pixel_data_ready(pixel_data_ready)
);

endmodule