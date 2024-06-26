
module dc_fu_dma_address_generator #(
  parameter FETCH_WORD_COUNT_WIDTH = 16,
  parameter AXI_ARADDR_WIDTH = 32,
  parameter MAX_BURST_LEN = 4,
  parameter READ_DATA_SIZE = 1
)(
  input wire clk,
  input wire en,
  input wire nrst,
  
  input wire start_fetch,
  input wire[(FETCH_WORD_COUNT_WIDTH-1):0] fetch_word_count,
  input wire[(AXI_ARADDR_WIDTH-1):0] base_addr,
  output wire unaligned_read,

  input wire next_addr,
  output wire[(AXI_ARADDR_WIDTH-1):0] axi_araddr,
  output wire[7:0] axi_arlen,
  output wire[(FETCH_WORD_COUNT_WIDTH-1-MAX_BURST_LEN):0] trans_count
);
  
  // store fetch_word_count value and detect unaligned reads
  wire[(FETCH_WORD_COUNT_WIDTH-1):0] prev_fetch_word_count_nxt_c;
  wire unaligned_read_nxt_c;
  wire prev_fetch_word_count_en_c;
  wire[(AXI_ARADDR_WIDTH-1):0] base_addr_aligned_c;
  reg[(FETCH_WORD_COUNT_WIDTH-1):0] prev_fetch_word_count_r;
  reg unaligned_read_r;
  assign prev_fetch_word_count_en_c = en && start_fetch;
  assign prev_fetch_word_count_nxt_c = fetch_word_count;
  assign unaligned_read_nxt_c = base_addr[0];
  assign base_addr_aligned_c = {base_addr[(AXI_ARADDR_WIDTH-1):1], 1'h0};  // doesnt affect even (aligned) addresses
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      prev_fetch_word_count_r <= '0;
      unaligned_read_r <= '0;
    end else if(prev_fetch_word_count_en_c) begin
      prev_fetch_word_count_r <= prev_fetch_word_count_nxt_c;
      unaligned_read_r <= unaligned_read_nxt_c;
    end
  end	  
  assign unaligned_read = unaligned_read_r;
  
  localparam TRANS_COUNT_WIDTH = FETCH_WORD_COUNT_WIDTH-MAX_BURST_LEN;
  localparam ADDR_DELTA = 2**MAX_BURST_LEN * 2**READ_DATA_SIZE;
  localparam ARLEN_MAX = 8'h2**MAX_BURST_LEN - 8'h1;
  //transaction cnt register
  reg[(TRANS_COUNT_WIDTH-1):0] trans_count_cnt_r;
  wire[(TRANS_COUNT_WIDTH-1):0] trans_count_cnt_nxt_c;
  wire[(TRANS_COUNT_WIDTH-1):0] trans_count_cnt_reset_val_c;
  wire[(TRANS_COUNT_WIDTH-1):0] fetch_word_count_incr_c;
  wire trans_count_cnt_en_c;
  assign fetch_word_count_incr_c = fetch_word_count[(FETCH_WORD_COUNT_WIDTH-1):MAX_BURST_LEN] 
                                      + TRANS_COUNT_WIDTH'('h1);
  assign trans_count_cnt_reset_val_c = (fetch_word_count[(MAX_BURST_LEN-1):0] == '0) ? 
                                       fetch_word_count[(FETCH_WORD_COUNT_WIDTH-1):MAX_BURST_LEN]:
                                       fetch_word_count_incr_c;
  assign trans_count_cnt_en_c = en && (next_addr || start_fetch);
  assign trans_count_cnt_nxt_c = (start_fetch) ? trans_count_cnt_reset_val_c : 
                                 (|trans_count_cnt_r) ? (trans_count_cnt_r - TRANS_COUNT_WIDTH'('h1)) : '0;
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      trans_count_cnt_r <= '0;
    end else if(trans_count_cnt_en_c) begin
      trans_count_cnt_r <= trans_count_cnt_nxt_c;
    end
  end
  assign trans_count = trans_count_cnt_r;
  
  //address and len generation register
  reg[(AXI_ARADDR_WIDTH-1):0] axi_araddr_r;
  reg[7:0] axi_arlen_r;
  wire[7:0] axi_arlen_nxt_c;
  wire[(AXI_ARADDR_WIDTH-1):0] axi_araddr_nxt_c;
  wire axi_araddr_en_c;
  wire trans_count_cnt_nxt_gt1_c;
  wire[7:0] last_tran_len_c;
  assign axi_araddr_en_c = en && (next_addr || start_fetch);
  assign trans_count_cnt_nxt_gt1_c = |trans_count_cnt_nxt_c[(TRANS_COUNT_WIDTH-1):1];
  // if line smaller than 16 words is being fetched, we must use last_tran_len_c
  // at the very begining, when prev_fetch_word_count_r doesn't hold valid value
  assign last_tran_len_c = (start_fetch) ?
                           {'0, fetch_word_count[(MAX_BURST_LEN-1):0] - MAX_BURST_LEN'('h1)} :
                           {'0, prev_fetch_word_count_r[(MAX_BURST_LEN-1):0] - MAX_BURST_LEN'('h1)};
  assign axi_arlen_nxt_c = (trans_count_cnt_nxt_gt1_c) ? 
                           ARLEN_MAX : 
                           last_tran_len_c;
  assign axi_araddr_nxt_c = (start_fetch) ? base_addr_aligned_c :
                            (trans_count_cnt_r > '0) ? 
                            (axi_araddr_r + ADDR_DELTA) : 
                            '0;  		                                                          
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      axi_araddr_r <= '0;
      axi_arlen_r <= '0;
    end else if(axi_araddr_en_c) begin
      axi_araddr_r <= axi_araddr_nxt_c;
      axi_arlen_r <= axi_arlen_nxt_c;
    end
  end	
  assign axi_araddr = axi_araddr_r;
  assign axi_arlen = axi_arlen_r[(MAX_BURST_LEN-1):0];
  
  
endmodule
