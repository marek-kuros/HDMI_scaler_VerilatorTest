module dc_ipu_filter_core_s1 #(
  parameter WEIGHTED_COLOR_FRACT_WIDTH,
  parameter WEIGHTED_COLOR_WIDTH,
  parameter COLOR_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire signed[WEIGHTED_COLOR_WIDTH-1:0] in_weighted_texel_matrix[0:3][0:3],

  output wire out_valid,
  input wire out_ready,
  output wire[COLOR_WIDTH-1:0] pixel_data
);

genvar i, j;

localparam ROW_SUM_WIDTH = WEIGHTED_COLOR_WIDTH + 2;
localparam MATRIX_SUM_WIDTH = ROW_SUM_WIDTH + 2;
localparam WEIGHTED_COLOR_MAX = {
  {(WEIGHTED_COLOR_WIDTH - WEIGHTED_COLOR_FRACT_WIDTH - COLOR_WIDTH){1'b0}},
  {COLOR_WIDTH{1'b1}},
  {WEIGHTED_COLOR_FRACT_WIDTH{1'b0}}}; 

wire buf_main_en;
wire buf_side_en;
wire buf_restore;
wire en = out_ready;
wire buf_valid;
wire signed[WEIGHTED_COLOR_WIDTH-1:0] buf_weighted_texel_matrix[0:3][0:3];

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

generate
  for (i = 0; i < 4; i++) begin : gb_texel_matrix_buffer_main
    for (j = 0; j < 4; j++) begin : gb_texel_matrix_buffer
      dc_ipu_shr_pipeline_buffer #(
        .WIDTH(WEIGHTED_COLOR_WIDTH)
      )
      u_texel_buffer(
        .clk(clk),
        .nreset(nreset),

        .buf_main_en(buf_main_en),
        .buf_side_en(buf_side_en),
        .buf_restore(buf_restore),

        .d(in_weighted_texel_matrix[i][j]),
        .q(buf_weighted_texel_matrix[i][j])
      );
    end
	end
endgenerate


// ------------------------------------- Valid flag chain for substages

dc_ipu_shr_pipeline_valid_chain #(
  .LENGTH(2)
)
u_valid_chain(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),
  
  .en(en),
  .in_valid(buf_valid),
  .out_valid(out_valid)
);

// ------------------------------------- Substage 0: Row sums

reg signed[ROW_SUM_WIDTH-1:0] row_sums_r[0:3];
wire signed[ROW_SUM_WIDTH-1:0] row_sums_nxt_c[0:3];
wire row_sums_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    row_sums_r <= '{default: '0};
  else if (row_sums_en_c)
    row_sums_r <= row_sums_nxt_c;

assign row_sums_nxt_c[0] =
  buf_weighted_texel_matrix[0][0] +
  buf_weighted_texel_matrix[1][0] +
  buf_weighted_texel_matrix[2][0] +
  buf_weighted_texel_matrix[3][0];

assign row_sums_nxt_c[1] =
  buf_weighted_texel_matrix[0][1] +
  buf_weighted_texel_matrix[1][1] +
  buf_weighted_texel_matrix[2][1] +
  buf_weighted_texel_matrix[3][1];

assign row_sums_nxt_c[2] =
  buf_weighted_texel_matrix[0][2] +
  buf_weighted_texel_matrix[1][2] +
  buf_weighted_texel_matrix[2][2] +
  buf_weighted_texel_matrix[3][2];

assign row_sums_nxt_c[3] =
  buf_weighted_texel_matrix[0][3] +
  buf_weighted_texel_matrix[1][3] +
  buf_weighted_texel_matrix[2][3] +
  buf_weighted_texel_matrix[3][3];

// ------------------------------------- Substage 1: Matrix sum

reg signed[MATRIX_SUM_WIDTH-1:0] matrix_sum_r;
wire signed [MATRIX_SUM_WIDTH-1:0] matrix_sum_nxt_c;
wire matrix_sum_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    matrix_sum_r <= '0;
  else if (matrix_sum_en_c)
    matrix_sum_r <= matrix_sum_nxt_c;

assign matrix_sum_nxt_c = 
  row_sums_r[0] +
  row_sums_r[1] +
  row_sums_r[2] +
  row_sums_r[3];

// ------------------------------------- Substage 2: Round and clamp

assign pixel_data =
  (matrix_sum_r[MATRIX_SUM_WIDTH-1])   ? '0  :               // Underflow
  (matrix_sum_r >= WEIGHTED_COLOR_MAX) ? '1  :               // Overflow
    (matrix_sum_r[WEIGHTED_COLOR_FRACT_WIDTH +: COLOR_WIDTH] // Rounding
    + matrix_sum_r[WEIGHTED_COLOR_FRACT_WIDTH-1]);

endmodule
