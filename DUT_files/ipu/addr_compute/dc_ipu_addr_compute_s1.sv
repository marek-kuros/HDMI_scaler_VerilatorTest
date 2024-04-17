/*
  This stage performs following operation:

  result = tex_size * (2x + 1)
*/
module dc_ipu_addr_compute_s1 #(
  parameter TEX_SIZE_WIDTH,
  parameter IMG_SIZE_WIDTH,
  parameter RESULT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire[IMG_SIZE_WIDTH-1:0] in_img_size,
  input wire[TEX_SIZE_WIDTH-1:0] in_tex_size,
  input wire[IMG_SIZE_WIDTH-1:0] in_x,

  output wire out_valid,
  input wire out_ready,
  output wire[IMG_SIZE_WIDTH-1:0] out_img_size,
  output wire[RESULT_WIDTH-1:0] out_result
);

// Directly propagate 'ready' from sink
wire en = out_ready;
assign in_ready = out_ready;

dc_ipu_shr_pipeline_valid_flag u_valid_flag(
  .clk(clk),
  .nreset(nreset),
  .en(en),
  .clr(clr),

  .in_valid(in_valid),
  .out_valid(out_valid)
);

reg[IMG_SIZE_WIDTH-1:0] img_size_r;
wire[IMG_SIZE_WIDTH-1:0] img_size_nxt_c = in_img_size;
wire img_size_en_c = en;

reg[TEX_SIZE_WIDTH-1:0] tex_size_r;
wire[TEX_SIZE_WIDTH-1:0] tex_size_nxt_c = in_tex_size;
wire tex_size_en_c = en;

reg[IMG_SIZE_WIDTH-1:0] x_r;
wire[IMG_SIZE_WIDTH-1:0] x_nxt_c = in_x;
wire x_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    img_size_r <= '0;
  else if (img_size_en_c)
    img_size_r <= img_size_nxt_c;

always @(posedge clk or negedge nreset)
  if (!nreset)
    tex_size_r <= '0;
  else if (tex_size_en_c)
    tex_size_r <= tex_size_nxt_c;

always @(posedge clk or negedge nreset)
  if (!nreset)
    x_r <= '0;
  else if (x_en_c)
    x_r <= x_nxt_c;

// Hopefully, Quartus instantiates the hardware multipliers here.
// If not, this should be replaced with a pipeline multiplication unit.
// We're doing tex_size * (2x + 1) here
assign out_result = tex_size_r * {x_r, 1'b1};
assign out_img_size = img_size_r;

endmodule
