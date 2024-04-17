//sources for DMA module of Fetch Unit

module dc_fu_dma_handshake_manager #(
  parameter FETCH_WORD_COUNT_WIDTH = 16,
  parameter MAX_BURST_LEN = 4
)(
  input wire clk,
  input wire nrst,
  input wire en,

  input wire[(FETCH_WORD_COUNT_WIDTH-MAX_BURST_LEN-1):0] trans_count,
  input wire start_fetch,

  input wire axi_arready,
  output wire axi_arvalid,
  input wire axi_rvalid,
  output wire axi_rready,
  input wire axi_rlast,
  input wire[1:0] axi_rresp,

  output wire next_addr,
  output wire[1:0] error_flag
);

  //fsm states
  localparam HANDSHAKE_MANAGER_FSM_WIDTH = 2;
  localparam HANDSHAKE_MANAGER_FSM_IDLE = HANDSHAKE_MANAGER_FSM_WIDTH'('h0);
  localparam HANDSHAKE_MANAGER_FSM_SEND_ADDR = HANDSHAKE_MANAGER_FSM_WIDTH'('h1);
  localparam HANDSHAKE_MANAGER_FSM_GET_NEW_ADDR = HANDSHAKE_MANAGER_FSM_WIDTH'('h2);
  
  reg[(HANDSHAKE_MANAGER_FSM_WIDTH-1):0] handshake_manager_fsm_r;
  reg[(HANDSHAKE_MANAGER_FSM_WIDTH-1):0] handshake_manager_fsm_nxt_c;
  wire handshake_manager_fsm_en_c;
  assign handshake_manager_fsm_en_c = en;
  always_comb begin
    case(handshake_manager_fsm_r)
      HANDSHAKE_MANAGER_FSM_IDLE:
        handshake_manager_fsm_nxt_c = (start_fetch) ? 
                                      HANDSHAKE_MANAGER_FSM_SEND_ADDR : 
                                      HANDSHAKE_MANAGER_FSM_IDLE;
      HANDSHAKE_MANAGER_FSM_SEND_ADDR:
        handshake_manager_fsm_nxt_c = (trans_count == '0) ? 
                                      HANDSHAKE_MANAGER_FSM_IDLE :  // trans_count equal to 0 means all trans are done
                                      (axi_arready) ? 
                                      HANDSHAKE_MANAGER_FSM_GET_NEW_ADDR :  // wait for ready
                                      HANDSHAKE_MANAGER_FSM_SEND_ADDR;
      HANDSHAKE_MANAGER_FSM_GET_NEW_ADDR:
        handshake_manager_fsm_nxt_c = HANDSHAKE_MANAGER_FSM_SEND_ADDR;
    endcase
  end 
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      handshake_manager_fsm_r <= HANDSHAKE_MANAGER_FSM_IDLE;
    end else if(handshake_manager_fsm_en_c) begin
      handshake_manager_fsm_r <= handshake_manager_fsm_nxt_c;
    end
  end

  reg axi_arvalid_nxt_c;
  reg axi_rready_nxt_c;
  reg[1:0] error_flag_nxt_c;
  reg axi_arvalid_r;
  reg axi_rready_r;
  reg[1:0] error_flag_r;
  reg next_addr_c;
  assign handshake_manager_outputs_en_c = en;
  always_comb begin
    case(handshake_manager_fsm_nxt_c)
      HANDSHAKE_MANAGER_FSM_IDLE: begin
        axi_arvalid_nxt_c = '0;
        axi_rready_nxt_c = 1'b1;
        error_flag_nxt_c = '0;
        next_addr_c = '0;
      end

      HANDSHAKE_MANAGER_FSM_SEND_ADDR: begin
        axi_arvalid_nxt_c = (trans_count != '0) || (handshake_manager_fsm_r == HANDSHAKE_MANAGER_FSM_IDLE);
        axi_rready_nxt_c = (trans_count != 1) || (handshake_manager_fsm_r == HANDSHAKE_MANAGER_FSM_IDLE);
        error_flag_nxt_c = '0;
        next_addr_c = '0;
      end

      HANDSHAKE_MANAGER_FSM_GET_NEW_ADDR: begin
        axi_arvalid_nxt_c = '0;
        axi_rready_nxt_c = 1'b1;
        error_flag_nxt_c = axi_rresp;
        next_addr_c = (handshake_manager_fsm_r == HANDSHAKE_MANAGER_FSM_SEND_ADDR);
      end
    endcase
  end
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      axi_arvalid_r <= '0;
      axi_rready_r <= '0;
      error_flag_r <= '0;
    end else if(handshake_manager_outputs_en_c) begin
      axi_arvalid_r <= axi_arvalid_nxt_c;
      axi_rready_r <= axi_rready_nxt_c;
      error_flag_r <= error_flag_nxt_c;
    end
  end
  assign next_addr = next_addr_c;
  assign axi_arvalid = axi_arvalid_r;
  assign axi_rready = 1'b1;
  assign error_flag = error_flag_r;

endmodule
