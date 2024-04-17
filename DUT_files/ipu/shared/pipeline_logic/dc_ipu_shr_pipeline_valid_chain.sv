/*
  A FIFO with synchronous clear
*/
module dc_ipu_shr_pipeline_valid_chain #(
  parameter LENGTH
)
(
  input wire clk,
  input wire nreset,
  input wire en,
  input wire clr,

  // TODO implement 'pipeline empty' signal

  input wire in_valid,
  output wire out_valid
);

wire valid_flags[0:LENGTH-1];

// Instantiate the first register
dc_ipu_shr_pipeline_valid_flag u_valid_flag(
  .clk(clk),
  .nreset(nreset),
  .en(en),
  .clr(clr),
  .in_valid(in_valid),
  .out_valid(valid_flags[0])
);

// Instantiate further registers
genvar i;
generate
  for (i = 1; i < LENGTH; i++) begin : gb_valid_chain
    dc_ipu_shr_pipeline_valid_flag u_valid_flag(
      .clk(clk),
      .nreset(nreset),
      .en(en),
      .clr(clr),
      .in_valid(valid_flags[i - 1]),
      .out_valid(valid_flags[i])
    );
  end
endgenerate
// Output
assign out_valid = valid_flags[LENGTH - 1];

endmodule
