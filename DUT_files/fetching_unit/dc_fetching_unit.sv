
module dc_fetching_unit #(
  parameter AXI_ARADDR_WIDTH = 32,
  parameter PIXELS_PER_LINE_WIDTH = 8,
  parameter LINE_NUMBER_WIDTH = 8,
  parameter READ_DATA_SIZE = 1,
  parameter FETCH_WORD_COUNT_WIDTH = 16,
  parameter MAX_BURST_LEN = 4,
  parameter BITS_PER_PIXEL
)(
  input wire clk,
  input wire en,
  input wire nrst,

  input wire[(AXI_ARADDR_WIDTH-1):0] frame_addr,
  input wire[(PIXELS_PER_LINE_WIDTH-1):0] pixels_per_line,
  input wire[(LINE_NUMBER_WIDTH-1):0] line_number, 
  input wire line_data_valid,
  output wire line_data_ready,

  //read address
  output wire[7:0] axi_arid,    
  output wire [(AXI_ARADDR_WIDTH-1):0] axi_araddr,  
  output wire[7:0] axi_arlen,   
  output wire[2:0] axi_arsize,  
  output wire[1:0] axi_arburst, 
  output wire[1:0] axi_arlock,  
  output wire[3:0] axi_arcache, 
  output wire[2:0] axi_arprot,  
  output wire[3:0] axi_arqos,   
  output wire[3:0] axi_arregion,
  output wire axi_arvalid, 
  input wire axi_arready, 

  //read data
  input wire[7:0] axi_rid,   
  input wire[15:0] axi_rdata, 
  input wire[1:0] axi_rresp, 
  input wire axi_rlast, 
  input wire axi_rvalid,
  output wire axi_rready,

  output wire[(BITS_PER_PIXEL-1):0] pixel_data,  
  output wire pixel_fifo_en
);

localparam BYTES_PER_PIXEL = BITS_PER_PIXEL/8;

wire start_fetch;
wire fetch_in_progress;
wire[(FETCH_WORD_COUNT_WIDTH-1):0] fetch_word_count;
wire[(AXI_ARADDR_WIDTH-1):0] line_addr;
wire[1:0] error_flag;

dc_fu_lines_translator #(
  .AXI_ARADDR_WIDTH(AXI_ARADDR_WIDTH),
  .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH),
  .LINE_NUMBER_WIDTH(LINE_NUMBER_WIDTH),
  .BYTES_PER_PIXEL(BYTES_PER_PIXEL),
  .READ_DATA_SIZE(READ_DATA_SIZE),
  .FETCH_WORD_COUNT_WIDTH(FETCH_WORD_COUNT_WIDTH)
)translator(
  .clk(clk),
  .en(en),
  .nrst(nrst),

  .frame_addr(frame_addr),
  .pixels_per_line(pixels_per_line),
  .line_number(line_number), 
  .line_data_valid(line_data_valid),
  .line_data_ready(line_data_ready),

  .start_fetch(start_fetch),
  .fetch_in_progress(fetch_in_progress),
  .fetch_word_count(fetch_word_count),
  .line_addr(line_addr),
  .error_flag(error_flag)
);

dc_fu_dma #(
    .FETCH_WORD_COUNT_WIDTH(FETCH_WORD_COUNT_WIDTH),
    .AXI_ARADDR_WIDTH(AXI_ARADDR_WIDTH),
    .READ_DATA_SIZE(READ_DATA_SIZE),
    .MAX_BURST_LEN(MAX_BURST_LEN)  
) dma(
    .clk(clk),
    .en(en),
    .nrst(nrst),
  
    .start_fetch(start_fetch),
    .fetch_in_progress(fetch_in_progress),
    .fetch_word_count(fetch_word_count),
    .base_addr(line_addr),
    .error_flag(error_flag),
  
    .axi_arid(axi_arid),  
    .axi_araddr(axi_araddr),  
    .axi_arlen(axi_arlen),   
    .axi_arsize(axi_arsize),  
    .axi_arburst(axi_arburst), 
    .axi_arlock(axi_arlock),  
    .axi_arcache(axi_arcache), 
    .axi_arprot(axi_arprot),  
    .axi_arqos(axi_arqos),   
    .axi_arregion(axi_arregion),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready), 
  
    .axi_rid(axi_rid),   
    .axi_rdata(axi_rdata), 
    .axi_rresp(axi_rresp), 
    .axi_rlast(axi_rlast), 
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready) 
  );

dc_fu_pixel_unpack #(
  .BITS_PER_PIXEL(BITS_PER_PIXEL)
)comb_3(
  .clk(clk),
  .en(en),
  .nrst(nrst),

  .axi_rvalid(axi_rvalid),
  .axi_rdata(axi_rdata),
  .fetch_in_progress(fetch_in_progress),
  .pixel_data(pixel_data),
  .pixel_fifo_en(pixel_fifo_en)
);

endmodule