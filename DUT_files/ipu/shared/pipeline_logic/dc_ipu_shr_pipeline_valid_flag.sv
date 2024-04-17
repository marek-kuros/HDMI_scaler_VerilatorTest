/*
  A single register storing valid flag
*/
module dc_ipu_shr_pipeline_valid_flag (
  input wire clk,
  input wire nreset,
  input wire en,
  input wire clr,

  input wire in_valid,
  output wire out_valid
);

reg data_r;
wire data_nxt_c;
wire data_en_c = en | clr;

// Input & output
assign data_nxt_c = in_valid & !clr;
assign out_valid = data_r;

always @(posedge clk or negedge nreset)
  if (!nreset)
    data_r <= '0;
  else if (data_en_c)
    data_r <= data_nxt_c;

endmodule
