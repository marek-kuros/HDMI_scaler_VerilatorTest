module dc_ipu_array_divider_test;

localparam A_WIDTH = 8;
localparam B_WIDTH = 8;

reg clk;
reg nreset;
reg clr;
reg[A_WIDTH-1:0] a;
reg[B_WIDTH-1:0] b;
wire[A_WIDTH-1:0] q;
wire[B_WIDTH-1:0] r;
wire[A_WIDTH-1:0] q_seq;
wire[B_WIDTH-1:0] r_seq;

reg in_valid;
wire in_ready;
wire in_transfer = in_valid & in_ready;

wire out_valid;
reg out_ready;
wire out_transfer = out_valid & out_ready;

int a_vals[0:10] = '{15, 10, 2, 12, 12, 255, 150, 16, 50, 21, 27};
int b_vals[0:10] = '{1, 5, 2, 3, 4, 15, 10, 128, 40, 3, 9};
int data_cnt;

dc_ipu_array_divider_comb #(.A_WIDTH(A_WIDTH), .B_WIDTH(B_WIDTH)) u_div(
  .a(a),
  .b(b),
  .q(q),
  .r(r)
);

dc_ipu_array_divider_seq #(.A_WIDTH(A_WIDTH), .B_WIDTH(B_WIDTH)) u_div_seq(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(in_valid),
  .in_ready(in_ready),
  .out_valid(out_valid),
  .out_ready(out_ready),

  .a(a),
  .b(b),
  .q(q_seq),
  .r(r_seq)
);

initial begin
  clk = 0;
  clr = 0;
  nreset = 0;
  data_cnt = 0;
  in_valid = 0;
  out_ready = 0;
  a = 0;
  b = 0;

  #1;
  clk = 1;
  #1;
  nreset = 1;
  clk = 0;
  #1;

  for (int i = 0; i < 64; i++) begin
    a = a_vals[data_cnt % 11];
    b = b_vals[data_cnt % 11];
    
    in_valid = (i != 10) && (i != 11);
    out_ready = (i != 5) && (i != 7) && (i != 8) && (i != 10);
    
    clr = (i == 32);

    if (in_valid & in_ready)
      data_cnt = data_cnt + 1;

    #1
    clk = 1;
    #1;
    clk = 0;
  end;


end

endmodule
