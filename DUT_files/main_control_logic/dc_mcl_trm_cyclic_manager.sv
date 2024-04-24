module dc_mcl_trm_cyclic_manager #(
  parameter SCR_SIZE_WIDTH,
  parameter WIDTH_MANAGER
)(
  input wire clk,
  input wire en,
  input wire nrst,

  input wire conf_ready,
  input wire user_int_valid,
  input wire[2:0] sw_layer_0_scaling,

  input wire[(SCR_SIZE_WIDTH-1):0] max_dim,
  input wire[(SCR_SIZE_WIDTH-1):0] min_dim,
  output wire[(SCR_SIZE_WIDTH-1):0] curr_dim
);

localparam CYCLIC_MODE_FSM_WIDTH = 3;
localparam CYCLIC_MODE_FSM_IDLE = CYCLIC_MODE_FSM_WIDTH'('h0);
localparam CYCLIC_MODE_FSM_INC = CYCLIC_MODE_FSM_WIDTH'('h1);
localparam CYCLIC_MODE_FSM_WAIT_INC = CYCLIC_MODE_FSM_WIDTH'('h2);
localparam CYCLIC_MODE_FSM_DEC = CYCLIC_MODE_FSM_WIDTH'('h3);
localparam CYCLIC_MODE_FSM_WAIT_DEC = CYCLIC_MODE_FSM_WIDTH'('h4);

reg[(CYCLIC_MODE_FSM_WIDTH-1):0] cyclic_mode_fsm_r;
reg[(CYCLIC_MODE_FSM_WIDTH-1):0] cyclic_mode_fsm_nxt_c;
wire cyclic_mode_fsm_en_c;
wire cyclic_scaling_en;

generate 
if(WIDTH_MANAGER)
  assign cyclic_scaling_en = sw_layer_0_scaling == 3'b100 ||
                        sw_layer_0_scaling == 3'b110;
else
  assign cyclic_scaling_en = sw_layer_0_scaling == 3'b101 || 
                        sw_layer_0_scaling == 3'b110;
endgenerate
assign cyclic_mode_fsm_en_c = en;

always_comb begin
  case(cyclic_mode_fsm_r)
    CYCLIC_MODE_FSM_IDLE:
      cyclic_mode_fsm_nxt_c = (user_int_valid && cyclic_scaling_en) ? 
                              CYCLIC_MODE_FSM_INC : 
                              CYCLIC_MODE_FSM_IDLE;
    CYCLIC_MODE_FSM_INC:
      cyclic_mode_fsm_nxt_c = (!cyclic_scaling_en) ? // turning cyclic modes off should reset them 
                              CYCLIC_MODE_FSM_IDLE : 
                              (conf_ready) ? // conf_ready == 1 means that handshake occured
                              CYCLIC_MODE_FSM_WAIT_INC :
                              CYCLIC_MODE_FSM_INC;
    CYCLIC_MODE_FSM_WAIT_INC:
      cyclic_mode_fsm_nxt_c = (!cyclic_scaling_en) ? 
                              CYCLIC_MODE_FSM_IDLE : 
                              (user_int_valid && !conf_ready && (curr_dim < max_dim)) ?
                              CYCLIC_MODE_FSM_INC :
                              (user_int_valid && !conf_ready && (curr_dim >= max_dim)) ?
                              CYCLIC_MODE_FSM_DEC :
                              CYCLIC_MODE_FSM_WAIT_INC;
    CYCLIC_MODE_FSM_DEC:
      cyclic_mode_fsm_nxt_c = (!cyclic_scaling_en) ? 
                              CYCLIC_MODE_FSM_IDLE : 
                              (conf_ready) ? 
                              CYCLIC_MODE_FSM_WAIT_DEC :
                              CYCLIC_MODE_FSM_DEC;
    CYCLIC_MODE_FSM_WAIT_DEC:
      cyclic_mode_fsm_nxt_c = (!cyclic_scaling_en) ? 
                              CYCLIC_MODE_FSM_IDLE : 
                              (user_int_valid && !conf_ready && (curr_dim > min_dim)) ? 
                              CYCLIC_MODE_FSM_DEC :
                              (user_int_valid && !conf_ready && (curr_dim <= min_dim)) ?
                              CYCLIC_MODE_FSM_INC :
                              CYCLIC_MODE_FSM_WAIT_DEC;
  endcase
end

always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    cyclic_mode_fsm_r <= CYCLIC_MODE_FSM_IDLE;
  end else if(cyclic_mode_fsm_en_c) begin
    cyclic_mode_fsm_r <= cyclic_mode_fsm_nxt_c;
  end
end

reg[(SCR_SIZE_WIDTH-1):0] curr_dim_r;
reg[(SCR_SIZE_WIDTH-1):0] curr_dim_nxt_c;
always_comb begin
  case(cyclic_mode_fsm_nxt_c)
    CYCLIC_MODE_FSM_IDLE: begin
      curr_dim_nxt_c = min_dim;
    end

    CYCLIC_MODE_FSM_INC: begin
      curr_dim_nxt_c = (cyclic_mode_fsm_r == CYCLIC_MODE_FSM_WAIT_INC ||
                        cyclic_mode_fsm_r == CYCLIC_MODE_FSM_WAIT_DEC) ? 
                       curr_dim_r + SCR_SIZE_WIDTH'('h1) :
                       curr_dim_r;
    end

    CYCLIC_MODE_FSM_WAIT_INC: begin
      curr_dim_nxt_c = curr_dim_r;
    end

    CYCLIC_MODE_FSM_DEC: begin
      curr_dim_nxt_c = (cyclic_mode_fsm_r == CYCLIC_MODE_FSM_WAIT_INC ||
                        cyclic_mode_fsm_r == CYCLIC_MODE_FSM_WAIT_DEC) ? 
                       curr_dim_r - SCR_SIZE_WIDTH'('h1) :
                       curr_dim_r;
    end

    CYCLIC_MODE_FSM_WAIT_DEC: begin
      curr_dim_nxt_c = curr_dim_r;
    end
  endcase
end

always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    curr_dim_r <= '0;
  end else if(cyclic_mode_fsm_en_c) begin
    curr_dim_r <= curr_dim_nxt_c;
  end
end
assign curr_dim = curr_dim_r;

endmodule