module dc_ipu_filter_nearest #(
  parameter COEFF_WIDTH,
  parameter RGB_WIDTH,
  parameter WEIGHT_WIDTH,
  parameter WEIGHT_FRACT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire[RGB_WIDTH-1:0] in_texel_matrix[0:3][0:3],
  input wire[COEFF_WIDTH-1:0] coeff_x,
  input wire[COEFF_WIDTH-1:0] coeff_y,

  output wire out_valid,
  input wire out_ready,
  output wire[RGB_WIDTH-1:0] out_texel_matrix[0:3][0:3],
  output wire signed[WEIGHT_WIDTH-1:0] out_weights_x[0:3],
  output wire signed[WEIGHT_WIDTH-1:0] out_weights_y[0:3]
);

genvar i;
genvar j;

wire en;
wire buf_valid;
wire buf_main_en;
wire buf_side_en;
wire buf_restore;

assign out_valid = buf_valid;
assign en = out_ready;

dc_ipu_shr_pipeline_logic u_pipeline_logic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .in_valid(in_valid),
  .in_ready(in_ready),
  
  .en(en),
  .valid(buf_valid)
);

// Buffered texel matrix
generate
  for (i = 0; i < 4; i++) begin : gb_texel_matrix_buffer_outer
    for (j = 0; j < 4; j++) begin : gb_texel_matrix_buffer_inner
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

// Coeff. x buffer
wire[COEFF_WIDTH-1:0] buf_coeff_x;
dc_ipu_shr_pipeline_buffer #(
  .WIDTH(COEFF_WIDTH)
)
u_coeff_x_buffer(
  .clk(clk),
  .nreset(nreset),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(coeff_x),
  .q(buf_coeff_x)
);

// Coeff. y buffer
wire[COEFF_WIDTH-1:0] buf_coeff_y;
dc_ipu_shr_pipeline_buffer #(
  .WIDTH(COEFF_WIDTH)
)
u_coeff_y_buffer(
  .clk(clk),
  .nreset(nreset),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(coeff_y),
  .q(buf_coeff_y)
);

localparam WEIGHT_INT_WIDTH = WEIGHT_WIDTH - WEIGHT_FRACT_WIDTH;

// Weight = 1.0
wire signed[WEIGHT_WIDTH-1:0] unit_weight_c = {
  {(WEIGHT_INT_WIDTH - 1){1'b0}},
  1'b1,
  {WEIGHT_FRACT_WIDTH{1'b0}}
};

wire coeff_x_cmp_c = buf_coeff_x[COEFF_WIDTH - 1];
wire coeff_y_cmp_c = buf_coeff_y[COEFF_WIDTH - 1];

assign out_weights_x[0] = '0;
assign out_weights_x[1] = coeff_x_cmp_c ? '0 : unit_weight_c; 
assign out_weights_x[2] = coeff_x_cmp_c ? unit_weight_c : '0;
assign out_weights_x[3] = '0;

assign out_weights_y[0] = '0;
assign out_weights_y[1] = coeff_y_cmp_c ? '0 : unit_weight_c;
assign out_weights_y[2] = coeff_y_cmp_c ? unit_weight_c : '0;
assign out_weights_y[3] = '0;
endmodule
