
module dc_fu_lines_translator #(
  parameter AXI_ARADDR_WIDTH = 32,
  parameter PIXELS_PER_LINE_WIDTH = 8,
  parameter LINE_NUMBER_WIDTH = 8,
  parameter BYTES_PER_PIXEL = 3,
  parameter READ_DATA_SIZE = 1,
  parameter FETCH_WORD_COUNT_WIDTH = 16
)(
  input wire clk,
  input wire en,
  input wire nrst,

  input wire[(AXI_ARADDR_WIDTH-1):0] frame_addr,
  input wire[(PIXELS_PER_LINE_WIDTH-1):0] pixels_per_line,
  input wire[(LINE_NUMBER_WIDTH-1):0] line_number, 
  input wire line_data_valid,
  output wire line_data_ready,

  output wire start_fetch,
  input wire fetch_in_progress,
  output wire[(FETCH_WORD_COUNT_WIDTH-1):0] fetch_word_count,
  output wire[(AXI_ARADDR_WIDTH-1):0] line_addr,
  input wire[1:0] error_flag
);

localparam FETCH_UNIT_FSM_WIDTH = 2;
localparam FETCH_UNIT_FSM_WAITING_FOR_REQUEST = FETCH_UNIT_FSM_WIDTH'('h0);
localparam FETCH_UNIT_FSM_START_FETCH = FETCH_UNIT_FSM_WIDTH'('h1);
localparam FETCH_UNIT_FSM_FETCH_IN_PROGRESS = FETCH_UNIT_FSM_WIDTH'('h2);

reg[(FETCH_UNIT_FSM_WIDTH-1):0] fetch_unit_fsm_r;
wire fetch_unit_fsm_en_c;
reg[(FETCH_UNIT_FSM_WIDTH-1):0] fetch_unit_fsm_nxt_c;
assign fetch_unit_fsm_en_c = en;
always_comb begin
  case(fetch_unit_fsm_r)
    FETCH_UNIT_FSM_WAITING_FOR_REQUEST:
      fetch_unit_fsm_nxt_c = (line_data_valid) ? FETCH_UNIT_FSM_START_FETCH :
                                                         FETCH_UNIT_FSM_WAITING_FOR_REQUEST;
    FETCH_UNIT_FSM_START_FETCH:
      fetch_unit_fsm_nxt_c = FETCH_UNIT_FSM_FETCH_IN_PROGRESS;
    FETCH_UNIT_FSM_FETCH_IN_PROGRESS:
      fetch_unit_fsm_nxt_c = (fetch_in_progress) ? FETCH_UNIT_FSM_FETCH_IN_PROGRESS:
                                                              FETCH_UNIT_FSM_WAITING_FOR_REQUEST;
  endcase
end
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    fetch_unit_fsm_r <= FETCH_UNIT_FSM_WAITING_FOR_REQUEST;
  end else if(fetch_unit_fsm_en_c) begin
    fetch_unit_fsm_r <= fetch_unit_fsm_nxt_c;
  end
end

wire fetch_unit_outputs_en_c;
reg start_fetch_nxt_c;
reg line_data_ready_nxt_c;
reg[(FETCH_WORD_COUNT_WIDTH-1):0] fetch_word_count_nxt_c;
reg[(AXI_ARADDR_WIDTH-1):0] line_addr_nxt_c;
wire[(FETCH_WORD_COUNT_WIDTH-1):0] line_bytes_count_c;
wire[(READ_DATA_SIZE-1):0] line_bytes_count_carry_c;
wire[(FETCH_WORD_COUNT_WIDTH-1):0] words_count_c;
wire[(FETCH_WORD_COUNT_WIDTH-READ_DATA_SIZE-1):0] words_count_aux_c;
reg start_fetch_r;
reg line_data_ready_r;
reg[(FETCH_WORD_COUNT_WIDTH-1):0] fetch_word_count_r;
reg[(AXI_ARADDR_WIDTH-1):0] line_addr_r;
assign fetch_unit_outputs_en_c = en;
assign line_bytes_count_c = pixels_per_line * BYTES_PER_PIXEL;
assign line_bytes_count_carry_c = line_bytes_count_c[(READ_DATA_SIZE-1):0];
assign words_count_aux_c = line_bytes_count_c[(FETCH_WORD_COUNT_WIDTH-1):READ_DATA_SIZE] + 
                         line_bytes_count_carry_c;
assign words_count_c = {{READ_DATA_SIZE{1'b0}}, words_count_aux_c};
always_comb begin
  case(fetch_unit_fsm_nxt_c)
    FETCH_UNIT_FSM_WAITING_FOR_REQUEST: begin
      start_fetch_nxt_c = '0;
      line_data_ready_nxt_c = 1'b1;
      fetch_word_count_nxt_c = '0;
      line_addr_nxt_c = '0;
    end
    FETCH_UNIT_FSM_START_FETCH: begin 
      start_fetch_nxt_c = 1'b1;
      line_data_ready_nxt_c = '0;
      fetch_word_count_nxt_c = words_count_c;
      line_addr_nxt_c = frame_addr + line_number * line_bytes_count_c;
    end
    FETCH_UNIT_FSM_FETCH_IN_PROGRESS: begin
      start_fetch_nxt_c = '0;
      line_data_ready_nxt_c = '0;
      fetch_word_count_nxt_c = '0;
      line_addr_nxt_c = '0;
    end
  endcase
end
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    start_fetch_r <= '0;
    line_data_ready_r <= '0;
    fetch_word_count_r <= '0;
    line_addr_r <= '0;
  end else if(fetch_unit_outputs_en_c) begin
    start_fetch_r <= start_fetch_nxt_c;
    line_data_ready_r <= line_data_ready_nxt_c;
    fetch_word_count_r <= fetch_word_count_nxt_c;
    line_addr_r <= line_addr_nxt_c;
  end
end
assign start_fetch = start_fetch_r;
assign line_data_ready = line_data_ready_r;
assign fetch_word_count = fetch_word_count_r;
assign line_addr = line_addr_r;

endmodule 
