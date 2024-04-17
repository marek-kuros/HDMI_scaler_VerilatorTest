/*
  A simple FIFO
*/
module dc_ipu_array_divider_shift_reg
#(
  parameter WIDTH,
  parameter LENGTH
)
(
  input wire clk,
  input wire nreset,
  input wire en,

  input wire[WIDTH-1:0] d,
  output wire[WIDTH-1:0] q
);

reg[WIDTH-1:0] data_r[0:LENGTH-1];
wire[WIDTH-1:0] data_nxt_c[0:LENGTH-1];
wire data_en_c = en;

// Input & output
assign data_nxt_c[0] = d;
assign q = data_r[LENGTH - 1];

// Interconnections
genvar i;
generate
  for (i = 1; i < LENGTH; i++) begin : gb_connections
    assign data_nxt_c[i] = data_r[i - 1];
  end
endgenerate
// Register activation
generate
  for (i = 0; i < LENGTH; i++) begin : gb_registers
    always @(posedge clk or negedge nreset)
      if (!nreset)
        data_r[i] <= '0;
      else if (data_en_c)
        data_r[i] <= data_nxt_c[i];
  end
endgenerate
endmodule
