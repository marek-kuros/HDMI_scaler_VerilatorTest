/*
  Unused module. Leaving here for reference.
*/

module dc_ipu_array_divider_comb #(
  parameter A_WIDTH,
  parameter B_WIDTH
)
(
  input wire[A_WIDTH-1:0] a,
  input wire[B_WIDTH-1:0] b,
  output wire[A_WIDTH-1:0] q,
  output wire[B_WIDTH-1:0] r
);

localparam STAGE_NUM = A_WIDTH;
localparam Q_WIDTH = A_WIDTH;
localparam R_WIDTH = B_WIDTH - 1;

wire stage_cout_c[0:STAGE_NUM-1];
wire[B_WIDTH:0] stage_a_c[0:STAGE_NUM-1];
wire[B_WIDTH:0] stage_b_c[0:STAGE_NUM-1];
wire[B_WIDTH:0] stage_r_c[0:STAGE_NUM-1];

// Stages instantiation
genvar i;
generate
  for (i = 0; i < STAGE_NUM; i++) begin : gb_dc_ipu_array_divider_stage_comb
    if (i < B_WIDTH) begin // Narrow stages
      dc_ipu_array_divider_stage_comb #(.WIDTH(B_WIDTH)) u_stage 
      (
        .a(stage_a_c[i][B_WIDTH-1:0]),
        .b(stage_b_c[i][B_WIDTH-1:0]),
        .r(stage_r_c[i][B_WIDTH-1:0]),
        .cin(1'b1),
        .cout(stage_cout_c[i])
      );
    end else begin // Wide stages
      dc_ipu_array_divider_stage_comb #(.WIDTH(B_WIDTH + 1)) u_stage 
      (
        .a(stage_a_c[i]),
        .b(stage_b_c[i]),
        .r(stage_r_c[i]),
        .cin(1'b1),
        .cout(stage_cout_c[i])
      );
    end
  end
endgenerate

// Remainder output
assign r = stage_r_c[STAGE_NUM - 1];

// Quotient outputs, inputs (B) and carry inputs
// Perhaps this should be an always_comb block?
generate
  for (i = 0; i < STAGE_NUM; i++) begin : gb_stage_connections
    assign stage_b_c[i] = b;
    assign q[Q_WIDTH - 1 - i] = stage_cout_c[i];
  end
endgenerate
// Stage inputs (A)
// Perhaps this should be an always_comb block?
assign stage_a_c[0] = a[A_WIDTH - 1];
generate
  for (i = 1; i < STAGE_NUM; i++) begin : gb_stage_inputs 
    assign stage_a_c[i] = {stage_r_c[i - 1], a[A_WIDTH - 1 - i]};
  end
endgenerate
endmodule
