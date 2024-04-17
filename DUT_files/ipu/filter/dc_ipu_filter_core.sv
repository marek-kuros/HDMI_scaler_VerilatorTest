module dc_ipu_filter_core #(
  parameter WEIGHT_WIDTH,
  parameter WEIGHT_FRACT_WIDTH,
  parameter COLOR_WIDTH
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
  output wire[COLOR_WIDTH-1:0] pixel_data
);

localparam WEIGHTED_COLOR_WIDTH = WEIGHT_WIDTH; // TODO maybe adjust this for better PSNR?
localparam WEIGHTED_COLOR_FRACT_WIDTH = WEIGHTED_COLOR_WIDTH - COLOR_WIDTH - 2;

wire s0_s1_valid;
wire s0_s1_ready;
wire signed[WEIGHTED_COLOR_WIDTH-1:0] s0_s1_weighted_texel_matrix[0:3][0:3];

// Stage 0 - weight/texel multiplication
dc_ipu_filter_core_s0 #(
  .WEIGHT_WIDTH(WEIGHT_WIDTH),
  .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH),
  .COLOR_WIDTH(COLOR_WIDTH),
  .WEIGHTED_COLOR_WIDTH(WEIGHTED_COLOR_WIDTH),
  .WEIGHTED_COLOR_FRACT_WIDTH(WEIGHTED_COLOR_FRACT_WIDTH)
)
u_stage0(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(in_valid),
  .in_ready(in_ready),
  .weights_matrix(weights_matrix),
  .texel_matrix(texel_matrix),
  
  .out_valid(s0_s1_valid),
  .out_ready(s0_s1_ready),
  .weighted_texel_matrix(s0_s1_weighted_texel_matrix)
);

// Stage 1 - summing
dc_ipu_filter_core_s1 #(
  .COLOR_WIDTH(COLOR_WIDTH),
  .WEIGHTED_COLOR_WIDTH(WEIGHTED_COLOR_WIDTH),
  .WEIGHTED_COLOR_FRACT_WIDTH(WEIGHTED_COLOR_FRACT_WIDTH)
)
u_stage1(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(s0_s1_valid),
  .in_ready(s0_s1_ready),
  .in_weighted_texel_matrix(s0_s1_weighted_texel_matrix),
  
  .out_valid(out_valid),
  .out_ready(out_ready),
  .pixel_data(pixel_data)
);

endmodule
