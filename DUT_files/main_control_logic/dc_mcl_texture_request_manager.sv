
module dc_mcl_texture_request_manager  #(
  parameter TEX_SIZE_WIDTH,
  parameter LINE_NUMBER_WIDTH
)(
  input wire clk,
  input wire nrst,
  input wire en,

  input wire frame_finished,
  input wire conf_valid,
  
  //IPU interface
  input wire tex_request_valid,
  output wire tex_request_ready,
  input wire[(TEX_SIZE_WIDTH-1):0] tex_request_y,
  
  // FU interface
  output wire[(LINE_NUMBER_WIDTH-1):0] line_number, 
  output wire line_data_valid,
  input wire line_data_ready,
  
  // BU interface
  output wire next_line,
  output wire no_func_switch,
  output wire output_en
);

localparam NUM_OF_LINES_FOR_IPU = 3'd4;

reg prefetch_occured_r;
reg prefetch_occured_nxt_c;
reg[2:0] prefetch_cnt_r;
reg[2:0] prefetch_cnt_nxt_c;

localparam TEX_REQUEST_FSM_WIDTH = 3;
localparam TEX_REQUEST_FSM_IDLE = TEX_REQUEST_FSM_WIDTH'('h0);
localparam TEX_REQUEST_FSM_WAIT_FOR_REQ = TEX_REQUEST_FSM_WIDTH'('h1);
localparam TEX_REQUEST_FSM_MULTIPLE_FETCH = TEX_REQUEST_FSM_WIDTH'('h2);
localparam TEX_REQUEST_FSM_PREFETCH_MATCHED = TEX_REQUEST_FSM_WIDTH'('h3);
localparam TEX_REQUEST_FSM_PREFETCH = TEX_REQUEST_FSM_WIDTH'('h5);
localparam TEX_REQUEST_FSM_PREFETCH_WAIT = TEX_REQUEST_FSM_WIDTH'('h6);
localparam TEX_REQUEST_FSM_NO_FETCH = TEX_REQUEST_FSM_WIDTH'('h7);

reg[(TEX_REQUEST_FSM_WIDTH-1):0] tex_request_fsm_r;
reg[(TEX_REQUEST_FSM_WIDTH-1):0] tex_request_fsm_nxt_c;
wire tex_request_en_c;
assign tex_request_en_c = en;
wire[(TEX_SIZE_WIDTH-1):0] prev_y_inc_c;

reg[(TEX_SIZE_WIDTH-1):0] prev_y_r;
reg[(TEX_SIZE_WIDTH-1):0] prev_y_nxt_c;
wire prev_y_en_c;
assign prev_y_inc_c = prev_y_r + TEX_SIZE_WIDTH'('h1);
assign prev_y_en_c = en && (tex_request_valid && tex_request_ready) || frame_finished;
assign prev_y_nxt_c = (frame_finished) ? '1 : tex_request_y;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    prev_y_r <= '1;
  end else if(prev_y_en_c) begin
    prev_y_r <= prev_y_nxt_c;
  end
end

wire tex_request_y_constant;
wire tex_request_y_incremented;
assign tex_request_y_constant = (tex_request_y == prev_y_r);
assign tex_request_y_incremented = (tex_request_y == prev_y_inc_c);
always_comb begin
  case(tex_request_fsm_r)
    TEX_REQUEST_FSM_IDLE:
      tex_request_fsm_nxt_c = (conf_valid) ?
                              TEX_REQUEST_FSM_MULTIPLE_FETCH :
                              TEX_REQUEST_FSM_IDLE;
    TEX_REQUEST_FSM_WAIT_FOR_REQ:
      tex_request_fsm_nxt_c = (frame_finished) ? 
                          TEX_REQUEST_FSM_IDLE :
                          (!prefetch_occured_r) ? 
                          TEX_REQUEST_FSM_PREFETCH :
                          (!tex_request_valid) ? 
                          TEX_REQUEST_FSM_WAIT_FOR_REQ : 
                          (tex_request_y_constant) ? 
                          TEX_REQUEST_FSM_NO_FETCH :
                          (tex_request_y_incremented) ?
                          TEX_REQUEST_FSM_PREFETCH_MATCHED :  // line is already fetched, no need for action
                          TEX_REQUEST_FSM_MULTIPLE_FETCH;
    TEX_REQUEST_FSM_MULTIPLE_FETCH:
      tex_request_fsm_nxt_c = (prefetch_cnt_r < NUM_OF_LINES_FOR_IPU + 3'd1) ? 
                          TEX_REQUEST_FSM_MULTIPLE_FETCH : 
                          TEX_REQUEST_FSM_WAIT_FOR_REQ;
    TEX_REQUEST_FSM_NO_FETCH:
      tex_request_fsm_nxt_c = TEX_REQUEST_FSM_WAIT_FOR_REQ;
    TEX_REQUEST_FSM_PREFETCH:
      tex_request_fsm_nxt_c = (line_data_ready) ? // wait for handshake
                          TEX_REQUEST_FSM_PREFETCH_WAIT : 
                          TEX_REQUEST_FSM_PREFETCH;
    TEX_REQUEST_FSM_PREFETCH_WAIT:
      tex_request_fsm_nxt_c = (line_data_ready) ? // ready goes high again when fetching is ready
                          TEX_REQUEST_FSM_WAIT_FOR_REQ : 
                          TEX_REQUEST_FSM_PREFETCH_WAIT;
    TEX_REQUEST_FSM_PREFETCH_MATCHED:
      tex_request_fsm_nxt_c = TEX_REQUEST_FSM_WAIT_FOR_REQ;
  endcase
end

always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    tex_request_fsm_r <= TEX_REQUEST_FSM_IDLE;
  end else if(tex_request_en_c) begin
    tex_request_fsm_r <= tex_request_fsm_nxt_c;
  end
end

reg tex_request_ready_r;
reg line_data_valid_r;
reg[(LINE_NUMBER_WIDTH-1):0] line_number_r;
reg next_line_r;
reg no_func_switch_r;
reg output_en_r;
reg tex_request_ready_nxt_c;
reg line_data_valid_nxt_c;
reg[(LINE_NUMBER_WIDTH-1):0] line_number_nxt_c;
reg next_line_nxt_c;
reg no_func_switch_nxt_c;
reg output_en_nxt_c;
wire mul_fetch_stage_complete;
//wire single_fetch_ocurred;
assign mul_fetch_stage_complete = line_data_ready && 
                                  (tex_request_fsm_r == TEX_REQUEST_FSM_MULTIPLE_FETCH);
//assign single_fetch_ocurred = (tex_request_fsm_r == TEX_REQUEST_FSM_PREFETCH_WAIT);
always_comb begin
  case(tex_request_fsm_nxt_c)
    TEX_REQUEST_FSM_IDLE: begin
      tex_request_ready_nxt_c = 1'h1;
      line_data_valid_nxt_c = '0;
      line_number_nxt_c = '0;
      prefetch_cnt_nxt_c = '0;
      next_line_nxt_c = '0;
      no_func_switch_nxt_c = '0;
      output_en_nxt_c = 1'h1;
      prefetch_occured_nxt_c = '0;
    end
    TEX_REQUEST_FSM_WAIT_FOR_REQ: begin
      tex_request_ready_nxt_c = 1'h1;
      line_data_valid_nxt_c = '0;
      line_number_nxt_c = '0;
      prefetch_cnt_nxt_c = '0;
      next_line_nxt_c = '0;
      no_func_switch_nxt_c = '0;
      output_en_nxt_c = !(tex_request_fsm_r == TEX_REQUEST_FSM_MULTIPLE_FETCH);  /* holds output_en at 0 for one cycle longer 
                                                                                    when transitioning from MULTIPLE_FETCH */  // update prev_y register
      prefetch_occured_nxt_c = prefetch_occured_r;
    end
    TEX_REQUEST_FSM_MULTIPLE_FETCH: begin
      tex_request_ready_nxt_c = '0;
      line_data_valid_nxt_c = (prefetch_cnt_r < NUM_OF_LINES_FOR_IPU);
      line_number_nxt_c = prefetch_cnt_r;  // we are assuming multiple fetch occurs only for first line of texture
      prefetch_cnt_nxt_c = (mul_fetch_stage_complete) ? 
                           prefetch_cnt_r + 3'h1 : 
                           prefetch_cnt_r;
      next_line_nxt_c = mul_fetch_stage_complete;
      no_func_switch_nxt_c = '0;
      output_en_nxt_c = '0;
      prefetch_occured_nxt_c = 1'h1;  
    end
    TEX_REQUEST_FSM_NO_FETCH: begin
      tex_request_ready_nxt_c = '0;
      line_data_valid_nxt_c = '0;
      line_number_nxt_c = '0;
      prefetch_cnt_nxt_c = '0;
      next_line_nxt_c = 1'h1;
      no_func_switch_nxt_c = 1'h1;
      output_en_nxt_c = 1'h1;
      prefetch_occured_nxt_c = prefetch_occured_r;
    end
    TEX_REQUEST_FSM_PREFETCH: begin
      tex_request_ready_nxt_c = '0;
      line_data_valid_nxt_c = 1'h1;
      line_number_nxt_c = prev_y_r + NUM_OF_LINES_FOR_IPU;
      prefetch_cnt_nxt_c = '0;
      next_line_nxt_c = '0;
      no_func_switch_nxt_c = '0;
      output_en_nxt_c = 1'h1;
      prefetch_occured_nxt_c = 1'h1;
    end
    TEX_REQUEST_FSM_PREFETCH_WAIT: begin
      tex_request_ready_nxt_c = '0;
      line_data_valid_nxt_c = '0;
      line_number_nxt_c = '0;
      prefetch_cnt_nxt_c = '0;
      next_line_nxt_c = '0;
      no_func_switch_nxt_c = '0;
      output_en_nxt_c = 1'h1;
      prefetch_occured_nxt_c = prefetch_occured_r;
    end
    TEX_REQUEST_FSM_PREFETCH_MATCHED: begin
      tex_request_ready_nxt_c = '0;
      line_data_valid_nxt_c = '0;
      line_number_nxt_c = '0;
      prefetch_cnt_nxt_c = '0;
      next_line_nxt_c = !(prev_y_r == '1);
      no_func_switch_nxt_c = '0;
      output_en_nxt_c = 1'h1;
      prefetch_occured_nxt_c = '0;
    end

  endcase
end

always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    tex_request_ready_r <= 0;
    line_data_valid_r <= '0;
    line_number_r <= '0;
    prefetch_cnt_r <= '0;
    next_line_r <= '0;
    no_func_switch_r <= '0;
    output_en_r <= '0;
    prefetch_occured_r <= '0;
  end else if(tex_request_en_c) begin
    tex_request_ready_r <= tex_request_ready_nxt_c;
    line_data_valid_r <= line_data_valid_nxt_c;
    line_number_r <= line_number_nxt_c;
    prefetch_cnt_r <= prefetch_cnt_nxt_c;
    next_line_r <= next_line_nxt_c;
    no_func_switch_r <= no_func_switch_nxt_c;
    output_en_r <= output_en_nxt_c;
    prefetch_occured_r <= prefetch_occured_nxt_c;
  end
end
assign tex_request_ready = tex_request_ready_r;
assign line_number = line_number_r;
assign line_data_valid = line_data_valid_r;
assign next_line = next_line_r;
assign no_func_switch = no_func_switch_r;
assign output_en = output_en_r;

endmodule
