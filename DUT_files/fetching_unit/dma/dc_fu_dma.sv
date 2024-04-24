module dc_fu_dma #(
  parameter FETCH_WORD_COUNT_WIDTH = 16,
  parameter AXI_ARADDR_WIDTH = 32,
  parameter READ_DATA_SIZE = 3'b1,  // 2 bytes on data bus
  parameter MAX_BURST_LEN = 4  // 16 bytes max im burst
)(
  input wire clk,
  input wire en,
  input wire nrst,

  input wire start_fetch,
  output wire fetch_in_progress,
  input wire[(FETCH_WORD_COUNT_WIDTH-1):0] fetch_word_count,
  input wire[(AXI_ARADDR_WIDTH-1):0] base_addr,
  output wire[1:0] error_flag,

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
  output wire axi_rready
);

//constant values
assign axi_arid = '0;  
assign axi_arsize = READ_DATA_SIZE;
assign axi_arburst = 2'b1;  // incr
assign axi_arlock = '0;
assign axi_arcache = '0;
assign axi_arprot = '0;
assign axi_arqos = '0; 
assign axi_arregion = '0;

wire[(FETCH_WORD_COUNT_WIDTH-MAX_BURST_LEN-1):0] trans_count;
wire next_addr;

dc_fu_dma_handshake_manager #(
    .FETCH_WORD_COUNT_WIDTH(FETCH_WORD_COUNT_WIDTH),
    .MAX_BURST_LEN(MAX_BURST_LEN)
) handshake_manager(
  .clk(clk),
  .nrst(nrst),
  .en(en),
  .trans_count(trans_count),
  .start_fetch(start_fetch),
  .axi_arready(axi_arready),
  .axi_rvalid(axi_rvalid),
  .axi_rlast(axi_rlast),
  .axi_rresp(axi_rresp),

  .axi_arvalid(axi_arvalid),
  .axi_rready(axi_rready),
  .next_addr(next_addr),
  .error_flag(error_flag)
);

dc_fu_dma_address_generator #(
  .FETCH_WORD_COUNT_WIDTH(FETCH_WORD_COUNT_WIDTH),
  .AXI_ARADDR_WIDTH(AXI_ARADDR_WIDTH),
  .MAX_BURST_LEN(MAX_BURST_LEN),
  .READ_DATA_SIZE(READ_DATA_SIZE)
) address_generator(
  .clk(clk),
  .en(en),
  .nrst(nrst),
  .start_fetch(start_fetch),
  .fetch_word_count(fetch_word_count),
  .base_addr(base_addr),

  .next_addr(next_addr),
  .axi_araddr(axi_araddr),
  .axi_arlen(axi_arlen),
  .trans_count(trans_count)
);

dc_fu_dma_fetching_progress_counter #(
  .FETCH_WORD_COUNT_WIDTH(FETCH_WORD_COUNT_WIDTH)
) progress_counter(
  .clk(clk),
  .nrst(nrst),
  .en(en),
  
  .start_fetch(start_fetch),
  .fetch_word_count(fetch_word_count),
  .axi_rvalid(axi_rvalid),
  .fetch_in_progress(fetch_in_progress)
);

endmodule