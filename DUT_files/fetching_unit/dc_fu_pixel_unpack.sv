
module dc_fu_pixel_unpack #(
  parameter BITS_PER_PIXEL,
  parameter READ_DATA_SIZE = 1
)(
  input wire clk,
  input wire en,
  input wire nrst,
  
  input wire unaligned_read,
  input wire axi_rvalid,
  input wire axi_rlast,
  input wire[((2**READ_DATA_SIZE)*8-1):0] axi_rdata,  // 8 represents bits in byte
  input wire fetch_in_progress,
  output wire[(BITS_PER_PIXEL-1):0] pixel_data,  // 8 represents bits in byte
  output wire pixel_fifo_en
);
  
  localparam READ_DATA_WIDTH = (2**READ_DATA_SIZE)*8;  // 8 represents bits in byte

  localparam PIXEL_UNPACK_FSM_WIDTH = 3;
  localparam PIXEL_UNPACK_FSM_IDLE = PIXEL_UNPACK_FSM_WIDTH'('h0);
  localparam PIXEL_UNPACK_FSM_FIRST_TWO_BYTES = PIXEL_UNPACK_FSM_WIDTH'('h1);
  localparam PIXEL_UNPACK_FSM_LAST_AND_FIRST = PIXEL_UNPACK_FSM_WIDTH'('h2);
  localparam PIXEL_UNPACK_FSM_TWO_LAST_BYTES = PIXEL_UNPACK_FSM_WIDTH'('h3);
  localparam PIXEL_UNPACK_FSM_FIRST_BYTE_UNALIGN = PIXEL_UNPACK_FSM_WIDTH'('h4);

  wire pixel_unpack_fsm_en;
  reg[(PIXEL_UNPACK_FSM_WIDTH-1):0] pixel_unpack_fsm_nxt_c;
  reg[(PIXEL_UNPACK_FSM_WIDTH-1):0] pixel_unpack_fsm_r;
  assign pixel_unpack_fsm_en = en;
  always_comb begin
    case(pixel_unpack_fsm_r)
      PIXEL_UNPACK_FSM_IDLE:
        pixel_unpack_fsm_nxt_c = (axi_rvalid && !unaligned_read) ? 
                                 PIXEL_UNPACK_FSM_FIRST_TWO_BYTES : 
                                 (axi_rvalid && unaligned_read) ? 
                                 PIXEL_UNPACK_FSM_FIRST_BYTE_UNALIGN :  // unaligned read, first byte is garbage
                                 PIXEL_UNPACK_FSM_IDLE;
      PIXEL_UNPACK_FSM_FIRST_BYTE_UNALIGN:
      pixel_unpack_fsm_nxt_c = (!fetch_in_progress) ? PIXEL_UNPACK_FSM_IDLE :
                                 (axi_rvalid) ? PIXEL_UNPACK_FSM_TWO_LAST_BYTES : 
                                 PIXEL_UNPACK_FSM_FIRST_BYTE_UNALIGN;
      PIXEL_UNPACK_FSM_FIRST_TWO_BYTES:
        pixel_unpack_fsm_nxt_c = (!fetch_in_progress) ? PIXEL_UNPACK_FSM_IDLE :
                                 (axi_rvalid) ? PIXEL_UNPACK_FSM_LAST_AND_FIRST : 
                                 PIXEL_UNPACK_FSM_FIRST_TWO_BYTES;
      PIXEL_UNPACK_FSM_LAST_AND_FIRST:
        pixel_unpack_fsm_nxt_c = (!fetch_in_progress) ? PIXEL_UNPACK_FSM_IDLE :                       
                                 (axi_rvalid) ? PIXEL_UNPACK_FSM_TWO_LAST_BYTES : 
                                 PIXEL_UNPACK_FSM_LAST_AND_FIRST;
      PIXEL_UNPACK_FSM_TWO_LAST_BYTES:
        pixel_unpack_fsm_nxt_c = (!fetch_in_progress) ? PIXEL_UNPACK_FSM_IDLE :
                                 (axi_rvalid) ? PIXEL_UNPACK_FSM_FIRST_TWO_BYTES : 
                                 PIXEL_UNPACK_FSM_TWO_LAST_BYTES;
    endcase
  end
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      pixel_unpack_fsm_r <= PIXEL_UNPACK_FSM_IDLE;
    end else if(pixel_unpack_fsm_en) begin
      pixel_unpack_fsm_r <= pixel_unpack_fsm_nxt_c;
    end
  end

  reg[(BITS_PER_PIXEL-1):0] pixel_data_nxt_c;
  reg[(READ_DATA_WIDTH-1):0] prev_rdata_nxt_c;
  reg[(BITS_PER_PIXEL-1):0] pixel_data_r;
  reg[(READ_DATA_WIDTH-1):0] prev_rdata_r; 
  wire pixel_unpack_outputs_en;
  assign pixel_unpack_outputs_en = en & axi_rvalid;
  always_comb begin
    case(pixel_unpack_fsm_nxt_c)
      PIXEL_UNPACK_FSM_IDLE: begin
        prev_rdata_nxt_c = '0;
        pixel_data_nxt_c = '0;
      end
      PIXEL_UNPACK_FSM_FIRST_BYTE_UNALIGN: begin
        prev_rdata_nxt_c = axi_rdata;
        pixel_data_nxt_c = '0;
      end
      PIXEL_UNPACK_FSM_FIRST_TWO_BYTES: begin
        prev_rdata_nxt_c = axi_rdata;
        pixel_data_nxt_c = pixel_data_r;
      end
      PIXEL_UNPACK_FSM_LAST_AND_FIRST: begin
        prev_rdata_nxt_c = axi_rdata;
        pixel_data_nxt_c = {axi_rdata[(READ_DATA_WIDTH/2-1):0], prev_rdata_r};
      end
      PIXEL_UNPACK_FSM_TWO_LAST_BYTES: begin
        prev_rdata_nxt_c = axi_rdata;
        pixel_data_nxt_c = {axi_rdata, prev_rdata_r[(READ_DATA_WIDTH-1):8]};
      end
    endcase
  end
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      pixel_data_r <= '0;
      prev_rdata_r <= '0;
    end else if(pixel_unpack_outputs_en) begin
      pixel_data_r <= pixel_data_nxt_c;
      prev_rdata_r <= prev_rdata_nxt_c;
    end
  end
  
  wire pixel_fifo_en_nxt_c;
  wire pixel_fifo_en_en_c;
  reg pixel_fifo_en_r;
  assign pixel_fifo_en_en_c = en;
  assign pixel_fifo_en_nxt_c = axi_rvalid & 
  ((pixel_unpack_fsm_nxt_c == PIXEL_UNPACK_FSM_LAST_AND_FIRST) || 
  (pixel_unpack_fsm_nxt_c == PIXEL_UNPACK_FSM_TWO_LAST_BYTES));
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin 
      pixel_fifo_en_r <= '0;
    end else if(pixel_fifo_en_en_c) begin
      pixel_fifo_en_r <= pixel_fifo_en_nxt_c;
    end
  end
  
  assign pixel_fifo_en = pixel_fifo_en_r;
  assign pixel_data = pixel_data_r;

endmodule 
