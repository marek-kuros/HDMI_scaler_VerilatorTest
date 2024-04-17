module dc_bu_write_manger #(
  parameter BUFF_ADDR_WIDTH = 7,
  parameter BUFFER_SIZE = 128,
  parameter BUFFER_NUM = 5,
  parameter PIXELS_PER_LINE_WIDTH
)(
  input wire clk, 
  input wire en,
  input wire nrst,
  
  input wire[(PIXELS_PER_LINE_WIDTH-1):0] pixels_per_line,
  input wire pixel_fifo_en,

  input wire next_line,
  input wire[(BUFFER_NUM-1):0] write_buffer_id, 

  output wire[(BUFF_ADDR_WIDTH-1):0] mem_addr,
  output wire[(BUFFER_NUM-1):0] we_vec
);

  localparam BUFF_MAX_ADDR = BUFFER_SIZE - 1;
  wire read_write_addr_lt_max;

  wire[(BUFF_ADDR_WIDTH-1):0] read_write_addr_cnt_nxt_c;
  wire[(BUFF_ADDR_WIDTH-1):0] read_write_addr_cnt_incr_c;
  wire read_write_addr_cnt_en_c;
  reg[(BUFF_ADDR_WIDTH-1):0] read_write_addr_cnt_r;
  assign read_write_addr_lt_max = read_write_addr_cnt_r < pixels_per_line;
  assign read_write_addr_cnt_en_c = en && (pixel_fifo_en || next_line);
  assign read_write_addr_cnt_incr_c = read_write_addr_cnt_r + BUFF_ADDR_WIDTH'('h1);
  assign read_write_addr_cnt_nxt_c = (next_line) ? '0 :
                                read_write_addr_lt_max ? 
                                read_write_addr_cnt_incr_c:
                                BUFF_ADDR_WIDTH'(BUFF_MAX_ADDR);
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      read_write_addr_cnt_r <= '0;
    end else if(read_write_addr_cnt_en_c) begin
      read_write_addr_cnt_r <= read_write_addr_cnt_nxt_c;
    end
  end
  assign mem_addr = read_write_addr_cnt_r;
  assign we_vec = (pixel_fifo_en && read_write_addr_lt_max) ? write_buffer_id : '0;

endmodule
