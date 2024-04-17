module dc_ipu_filter_outer_product #(
  parameter RGB_WIDTH,
  parameter WEIGHT_FRACT_WIDTH,
  parameter WEIGHT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire[RGB_WIDTH-1:0] in_texel_matrix[0:3][0:3],
  input wire signed[WEIGHT_WIDTH-1:0] weights_x[0:3],
  input wire signed[WEIGHT_WIDTH-1:0] weights_y[0:3],
  
  output wire out_valid,
  input wire out_ready,
  output wire[RGB_WIDTH-1:0] out_texel_matrix[0:3][0:3],
  output wire signed[WEIGHT_WIDTH-1:0] weights_matrix[0:3][0:3]
);

genvar i, j;

// ------------------------------------- Pipelines 0-15 weight multipliers

/*
  Note: We're not interested in multipliers' in_valid, out_ready signals.
        They are always expected to be in sync with the texel data passthrough.
        If multiplier implementation ever changes, the delay in the passthrough
        pipeline will have to be changed.

        Maybe we could add some assertions on this?
*/

generate
  for (i = 0; i < 4; i++) begin : gb_weight_cross_multiply_main
    for (j = 0; j < 4; j++) begin : gb_weight_cross_multiply
      wire signed[WEIGHT_WIDTH*2-1:0] result;
      assign weights_matrix[i][j] = result[WEIGHT_FRACT_WIDTH +: WEIGHT_WIDTH];

      dc_ipu_mul_unit_multiplier #(
        .WIDTH_A(WEIGHT_WIDTH),
        .WIDTH_B(WEIGHT_WIDTH)
      )
      u_mul(
        .clk(clk),
        .nreset(nreset),
        .clr(clr),
        
        .in_valid(in_valid),
        .in_ready(),            // Unused
        .value_a(weights_x[i]),
        .value_b(weights_y[j]),

        .out_valid(),           // Unused
        .out_ready(out_ready),
        .result(result)
      );
    end
	end
endgenerate

// ------------------------------------- Pipeline 16 - texel data passthrough

wire buf_main_en;
wire buf_side_en;
wire buf_restore;

dc_ipu_shr_pipeline_logic u_pipeline_logic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),
  
  .in_valid(in_valid),
  .in_ready(in_ready),

  .en(out_ready),
  .valid(out_valid)
);

generate
  for (i = 0; i < 4; i++) begin : gb_texel_matrix_buffer_main
    for (j = 0; j < 4; j++) begin : gb_texel_matrix_buffer
      dc_ipu_shr_pipeline_buffer #(
        .WIDTH(RGB_WIDTH)
      )
      u_texel_buffer(
        .clk(clk),
        .nreset(nreset),
        .buf_main_en(buf_main_en),
        .buf_side_en(buf_side_en),
        .buf_restore(buf_restore),
        .d(in_texel_matrix[i][j]),
        .q(out_texel_matrix[i][j])
      );
    end
	end
endgenerate

endmodule
