module dc_ipu_filter_core_s0 #(
  parameter WEIGHT_WIDTH,
  parameter WEIGHT_FRACT_WIDTH,
  parameter COLOR_WIDTH,
  parameter WEIGHTED_COLOR_WIDTH,
  parameter WEIGHTED_COLOR_FRACT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire signed[WEIGHT_WIDTH-1:0] weights_matrix[0:3][0:3],
  input wire[COLOR_WIDTH-1:0] texel_matrix[0:3][0:3],

  output wire out_valid,
  input wire out_ready,
  output wire signed[WEIGHTED_COLOR_WIDTH-1:0] weighted_texel_matrix[0:3][0:3]
);

genvar i, j;

generate
  for (i = 0; i < 4; i++) begin: gb_texel_weight_matrix_multiply_main
    for (j = 0; j < 4; j++) begin : gb_texel_weight_matrix_multiply
      
      wire signed[WEIGHT_WIDTH-1:0] color_wide = {{(WEIGHT_WIDTH - COLOR_WIDTH){4'b0}}, texel_matrix[i][j]};
      wire signed[2*WEIGHT_WIDTH-1:0] result_wide;
      wire tmp_in_ready, tmp_out_valid;

      dc_ipu_mul_unit_multiplier #(
        .WIDTH_A(WEIGHT_WIDTH),
        .WIDTH_B(WEIGHT_WIDTH)
      ) u_multiplier(
        .clk(clk),
        .nreset(nreset),
        .clr(clr),

        .in_valid(in_valid),
        .in_ready(tmp_in_ready),
        .value_a(weights_matrix[i][j]),
        .value_b(color_wide),

        .out_valid(tmp_out_valid),
        .out_ready(out_ready),
        .result(result_wide)
      );

      // We use the 1st multiplier as reference
      // The others *must* behave in the same way
      // TODO: Add an assertion on that?
      if (i == 0 && j == 0) begin
        assign in_ready = tmp_in_ready;
        assign out_valid = tmp_out_valid;
      end

      assign weighted_texel_matrix[i][j] =
        result_wide[(WEIGHT_FRACT_WIDTH-WEIGHTED_COLOR_FRACT_WIDTH) +: WEIGHTED_COLOR_WIDTH];
    end
	end
endgenerate

endmodule
