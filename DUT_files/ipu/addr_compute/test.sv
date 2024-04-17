module dc_ipu_addr_compute_test;

localparam IMG_SIZE_WIDTH = 12;
localparam TEX_SIZE_WIDTH = 12;
localparam TEX_FRACT_WIDTH = 12;

reg clk;
reg nreset;
reg clr;

reg[IMG_SIZE_WIDTH-1:0] img_size;
reg[TEX_SIZE_WIDTH-1:0] tex_size;
reg[IMG_SIZE_WIDTH-1:0] x;

wire[TEX_SIZE_WIDTH-1:0] tex_int;
wire[TEX_FRACT_WIDTH-1:0] tex_fract;

reg in_valid;
wire in_ready;
wire in_transfer = in_valid & in_ready;

wire out_valid;
reg out_ready;
wire out_transfer = out_valid & out_ready;

int data_cnt;
real tex_pos;

dc_ipu_addr_compute #(
  .IMG_SIZE_WIDTH(IMG_SIZE_WIDTH),
  .TEX_SIZE_WIDTH(TEX_SIZE_WIDTH),
  .TEX_FRACT_WIDTH(TEX_FRACT_WIDTH)
)
u_addr_compute(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(in_valid),
  .in_ready(in_ready),
  .out_valid(out_valid),
  .out_ready(out_ready),

  .x(x),
  .img_size(img_size),
  .tex_size(tex_size),
  
  .tex_addr(tex_int),
  .tex_addr_fract(tex_fract)
);

always @(posedge clk)
  if (out_valid & out_ready)
    tex_pos <= $signed(tex_int) + $itor(tex_fract) / (2 ** TEX_FRACT_WIDTH);

initial begin
  clk = 0;
  clr = 0;
  nreset = 0;
  data_cnt = 0;
  in_valid = 0;
  out_ready = 0;
  img_size = 4;
  tex_size = 2;

  #1;
  clk = 1;
  #1;
  nreset = 1;
  clk = 0;
  #1;

  for (int i = 0; i < 128; i++) begin
    x = data_cnt;

    in_valid = (i != 10) && (i != 11);
    out_ready = (i != 5) && (i != 7) && (i != 8) && (i != 10);
    
    clr = (i == 64);

    if (in_valid & in_ready)
      data_cnt = data_cnt + 1;

    #1;
    clk = 1;
    #1;
    clk = 0;
  end

end

endmodule
