/*
  Computes texture coordinates and interpolation coefficients from
  output image coordinates, its size and the texture size.

  The real sample position is computed as:
  n_t = N_t * (2n_o + 1) / 2N_o - 1/2

  Stage 1: compute tex_size * (2x + 1)
  Stage 2: divide by image_size
  Stage 3: divide by two, subtract 0.5 and split integral and fractional parts
*/
module dc_ipu_addr_compute #(
  parameter IMG_SIZE_WIDTH,
  parameter TEX_SIZE_WIDTH,
  parameter TEX_FRACT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire[IMG_SIZE_WIDTH-1:0] x,
  input wire[IMG_SIZE_WIDTH-1:0] img_size,
  input wire[TEX_SIZE_WIDTH-1:0] tex_size,

  output wire out_valid,
  input wire out_ready,
  output wire signed[TEX_SIZE_WIDTH-1:0] tex_addr,
  output wire[TEX_FRACT_WIDTH-1:0] tex_addr_fract
);

wire buf_main_en;
wire buf_side_en;
wire buf_restore;

wire s1_in_valid;
wire s1_in_ready;
dc_ipu_shr_pipeline_logic u_pipeline_logic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),
  .en(s1_in_ready),
  .valid(s1_in_valid),
  .in_valid(in_valid),
  .in_ready(in_ready),
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore)
);

wire[IMG_SIZE_WIDTH-1:0] x_r;
dc_ipu_shr_pipeline_buffer #(.WIDTH(IMG_SIZE_WIDTH)) u_buf_x(
  .clk(clk),
  .nreset(nreset),
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),
  .d(x),
  .q(x_r)
);

wire[IMG_SIZE_WIDTH-1:0] img_size_r;
dc_ipu_shr_pipeline_buffer #(.WIDTH(IMG_SIZE_WIDTH)) u_buf_img_size(
  .clk(clk),
  .nreset(nreset),
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),
  .d(img_size),
  .q(img_size_r)
);

wire[TEX_SIZE_WIDTH-1:0] tex_size_r;
dc_ipu_shr_pipeline_buffer #(.WIDTH(TEX_SIZE_WIDTH)) u_buf_tex_size(
  .clk(clk),
  .nreset(nreset),
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),
  .d(tex_size),
  .q(tex_size_r)
);

// Stage 1
// Would be cool if we could instead somehow extract S1_RESULT_WIDTH from the module. Is that possible?
localparam S1_RESULT_WIDTH = TEX_SIZE_WIDTH + IMG_SIZE_WIDTH; 
wire s1_s2_valid;
wire s1_s2_ready;
wire[TEX_SIZE_WIDTH-1:0] s1_s2_img_size;
wire[S1_RESULT_WIDTH-1:0] s1_s2_result;
dc_ipu_addr_compute_s1 #(
  .TEX_SIZE_WIDTH(TEX_SIZE_WIDTH),
  .IMG_SIZE_WIDTH(IMG_SIZE_WIDTH),
  .RESULT_WIDTH(S1_RESULT_WIDTH)
)
u_s1(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(s1_in_valid),
  .in_ready(s1_in_ready),
  .in_tex_size(tex_size_r),
  .in_img_size(img_size_r),
  .in_x(x_r),

  .out_valid(s1_s2_valid),
  .out_ready(s1_s2_ready),
  .out_img_size(s1_s2_img_size),
  .out_result(s1_s2_result)
);

// Stage 2
// Before division TEX_FRACT_WIDTH zeros are appended to the dividend
localparam S2_A_WIDTH = S1_RESULT_WIDTH + TEX_FRACT_WIDTH;
localparam S2_B_WIDTH = IMG_SIZE_WIDTH;
localparam S2_Q_WIDTH = S2_A_WIDTH;
localparam S2_R_WIDTH = S2_B_WIDTH;
wire[S2_A_WIDTH-1:0] s2_a = {s1_s2_result, {TEX_FRACT_WIDTH{1'b0}}};
wire s2_s3_valid;
wire s2_s3_ready;
wire[S2_Q_WIDTH-1:0] s2_s3_q;
wire[S2_R_WIDTH-1:0] s2_s3_r;
dc_ipu_array_divider_seq #(
  .A_WIDTH(S2_A_WIDTH),
  .B_WIDTH(S2_B_WIDTH)
)
u_s2(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(s1_s2_valid),
  .in_ready(s1_s2_ready),
  .a(s2_a),
  .b(s1_s2_img_size),

  .out_valid(s2_s3_valid),
  .out_ready(s2_s3_ready),
  .q(s2_s3_q),
  .r(s2_s3_r)
);

// Stage 3
dc_ipu_addr_compute_s3 #(
  .DATA_WIDTH(S2_Q_WIDTH),
  .FRACT_WIDTH(TEX_FRACT_WIDTH),
  .INT_WIDTH(TEX_SIZE_WIDTH)
)
u_s3(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),
  
  .in_valid(s2_s3_valid),
  .in_ready(s2_s3_ready),
  .in_data(s2_s3_q),
  
  .out_valid(out_valid),
  .out_ready(out_ready),
  .out_int(tex_addr),
  .out_fract(tex_addr_fract)
);

// Unused
wire unused_ok_c = &{s2_s3_r};

endmodule
