module dc_ipu_array_divider_seq #(
  parameter A_WIDTH,
  parameter B_WIDTH
)
(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  output wire out_valid,
  input wire out_ready,

  input wire[A_WIDTH-1:0] a,
  input wire[B_WIDTH-1:0] b,
  output wire[A_WIDTH-1:0] q,
  output wire[B_WIDTH-1:0] r
);

localparam STAGE_NUM = A_WIDTH;
localparam NARROW_STAGE_NUM = B_WIDTH;
localparam NARROW_STAGE_WIDTH = B_WIDTH;
localparam WIDE_STAGE_WIDTH = B_WIDTH + 1;

// Local enable signal
wire en = out_ready;

// Registered inputs
wire[A_WIDTH-1:0] a_buf;
wire[B_WIDTH-1:0] b_buf;

// Pipeline logic control signals
wire buf_main_en;
wire buf_side_en;
wire buf_restore;
wire buf_valid;

// Pipeline logic & buffers
dc_ipu_shr_pipeline_logic u_pipeline_logic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(in_valid),
  .in_ready(in_ready),
  .valid(buf_valid),
  .en(en),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore)
);

// Buffer for the A value
dc_ipu_shr_pipeline_buffer #(.WIDTH(A_WIDTH)) u_pipeline_buffer_a(
  .clk(clk),
  .nreset(nreset),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(a),
  .q(a_buf)
);

// Buffer for the B value
dc_ipu_shr_pipeline_buffer #(.WIDTH(B_WIDTH)) u_pipeline_buffer_b(
  .clk(clk),
  .nreset(nreset),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(b),
  .q(b_buf)
);

// Valid flag shift register
// Fed from the pipeline control logic
// Controls the out_valid block signal
dc_ipu_shr_pipeline_valid_chain #(.LENGTH(STAGE_NUM)) u_valid_chain(
  .clk(clk),
  .nreset(nreset),
  .en(en),
  .clr(clr),

  .in_valid(buf_valid),
  .out_valid(out_valid)
);


// Unused
wire unused_b_out_msb_c[NARROW_STAGE_NUM:STAGE_NUM-1];

// Stage connections
wire[WIDE_STAGE_WIDTH-1:0] stage_a_c[0:STAGE_NUM-1];
wire[WIDE_STAGE_WIDTH-1:0] stage_r_c[0:STAGE_NUM-1];
wire[B_WIDTH-1:0] stage_b_c[0:STAGE_NUM-1];
wire[B_WIDTH-1:0] stage_b_out_c[0:STAGE_NUM-1];
wire stage_cout_c[0:STAGE_NUM-1];

// Stages instantiation
genvar i, j;
generate
  for (i = 0; i < STAGE_NUM; i++) begin : gb_dc_ipu_array_divider_stage_seq
    if (i < NARROW_STAGE_NUM) begin : gb_dc_ipu_array_divider_stage_seq_narrow // Narrow stages
      dc_ipu_array_divider_stage_seq #(.WIDTH(NARROW_STAGE_WIDTH)) u_narrow_stage 
      (
        .clk(clk),
        .en(en),
        .nreset(nreset),
        .a(stage_a_c[i][NARROW_STAGE_WIDTH-1:0]),
        .b(stage_b_c[i]),
        .r(stage_r_c[i][NARROW_STAGE_WIDTH-1:0]),
        .b_out(stage_b_out_c[i]),
        .cout(stage_cout_c[i])
      );

      assign stage_r_c[i][NARROW_STAGE_WIDTH] = '0;
      
    end else begin : gb_dc_ipu_array_divider_stage_seq_wide // Wide stages
      dc_ipu_array_divider_stage_seq #(.WIDTH(WIDE_STAGE_WIDTH)) u_wide_stage 
      (
        .clk(clk),
        .en(en),
        .nreset(nreset),
        .a(stage_a_c[i]),
        .b({1'b0, stage_b_c[i]}),
        .r(stage_r_c[i]),
        .b_out({unused_b_out_msb_c[i], stage_b_out_c[i]}),
        .cout(stage_cout_c[i])
      );
    end
  end
endgenerate

// Remainder output
assign r = stage_r_c[STAGE_NUM - 1][B_WIDTH-1:0];

// First stage inputs
assign stage_b_c[0] = b_buf;
assign stage_a_c[0] = a_buf[A_WIDTH - 1];

// Inter-stage connections
// Perhaps this should be an always_comb block?
generate
  for (i = 1; i < STAGE_NUM; i++) begin : gb_dc_ipu_array_divider_stage_connections
    // LSB is fed from the A shift register
    assign stage_a_c[i][WIDE_STAGE_WIDTH-1:1] = stage_r_c[i - 1][NARROW_STAGE_WIDTH-2:0]; 
    assign stage_b_c[i] = stage_b_out_c[i - 1];
  end
endgenerate
// A shift registers
generate
  for (i = 0; i < STAGE_NUM - 1; i++) begin : gb_dc_ipu_array_divider_shift_reg_a
    dc_ipu_array_divider_shift_reg #(.WIDTH(1), .LENGTH(STAGE_NUM - 1 - i)) u_a_shift_reg(
      .clk(clk),
      .nreset(nreset),
      .en(en),
      .d(a_buf[i]),
      .q(stage_a_c[STAGE_NUM - 1 - i][0])
    );
  end
endgenerate
// Q shift registers
assign q[0] = stage_cout_c[STAGE_NUM - 1];
generate
  for (i = 1; i < STAGE_NUM; i++) begin : gb_dc_ipu_array_divider_shift_reg_q
    dc_ipu_array_divider_shift_reg #(.WIDTH(1), .LENGTH(i)) u_q_shift_reg(
      .clk(clk),
      .nreset(nreset),
      .en(en),
      .d(stage_cout_c[STAGE_NUM - 1 - i]),
      .q(q[i])
    );
  end
endgenerate
endmodule
