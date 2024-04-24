
module dc_fu_dma_fetching_progress_counter #(
  parameter FETCH_WORD_COUNT_WIDTH = 16
)(
  input wire clk,
  input wire nrst,
  input wire en,
  
  input wire start_fetch,
  input wire[(FETCH_WORD_COUNT_WIDTH-1):0] fetch_word_count,
  input wire axi_rvalid,
  output wire fetch_in_progress
);

  wire[(FETCH_WORD_COUNT_WIDTH-1):0] fetched_words_cnt_nxt_c;
  wire[(FETCH_WORD_COUNT_WIDTH-1):0] fetched_words_cnt_decr_c;
  wire fetched_words_en_c;
  reg[(FETCH_WORD_COUNT_WIDTH-1):0] fetched_words_cnt_r;
  assign fetched_words_en_c = (axi_rvalid || start_fetch) && en;
  assign fetched_words_cnt_decr_c = fetched_words_cnt_r - FETCH_WORD_COUNT_WIDTH'('h1);
  assign fetched_words_cnt_nxt_c = (start_fetch) ? fetch_word_count :
                                   (fetched_words_cnt_r > '0) ? 
                                   fetched_words_cnt_decr_c : 
                                   '0;
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      fetched_words_cnt_r <= '0;
    end else if(fetched_words_en_c) begin
      fetched_words_cnt_r <= fetched_words_cnt_nxt_c;
    end
  end
  
  assign fetch_in_progress = (fetched_words_cnt_r != '0);

endmodule