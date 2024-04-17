module dc_ipu_shr_pipeline_logic_test;

reg clk;
reg nreset;
reg clr;

wire prev_ready;
reg prev_valid;
wire in_transfer = prev_ready & prev_valid;

reg next_ready;
wire next_valid;
wire out_transfer = next_ready & next_valid;

int data_cnt;
reg[7:0] data_in;
wire[7:0] data_out;

dc_ipu_shr_pipeline_logic u_pip_logic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .en(next_ready),
  .valid(next_valid),

  .in_valid(prev_valid),
  .in_ready(prev_ready),

  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore)
  
);

dc_ipu_shr_pipeline_buffer #(.WIDTH(8)) u_pip_buf(
  .clk(clk),
  .nreset(nreset),
  
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),
  
  .d(data_in),
  .q(data_out)
);

initial begin
  prev_valid = 0;
  next_ready = 1;  
  data_in = 0;
  data_cnt = 0;
  clr = 0;

  clk = 0;
  nreset = 0;
  #1;
  clk = 1;
  #1;
  nreset = 1;
  clk = 0;
  #1;

  for (int i = 0; i < 64; i++) begin
    data_in = data_cnt;

    prev_valid = (i != 10) && (i != 11);
    next_ready = (i != 5) && (i != 7) && (i != 8) && (i != 10);

    clr = (i == 30);

    if (prev_valid & prev_ready)
          data_cnt = data_cnt + 1;

    #1
    clk = 1;
    #1;
    clk = 0;
  end;


end

endmodule
