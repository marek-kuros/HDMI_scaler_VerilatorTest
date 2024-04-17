/*
  Array divider combinational stage
*/
module dc_ipu_array_divider_stage_comb #(
  parameter WIDTH
)
(
  input wire[WIDTH-1:0] a,
  input wire[WIDTH-1:0] b,
  output wire[WIDTH-1:0] r,
  output wire cout,
  input wire cin
);

// Carry chain
wire cout_c[0:WIDTH-1];
wire cin_c[0:WIDTH-1];

assign cin_c[0] = cin;
wire s_c = cout_c[WIDTH - 1];
assign cout = s_c;

genvar i;

// Instantiate cells
generate
  for (i = 0; i < WIDTH; i++) begin : gb_dc_ipu_array_divider_cell
    dc_ipu_array_divider_cell u_cell(
      .a(a[i]),
      .b(b[i]),
      .s(s_c),
      .r(r[i]),
      .cin(cin_c[i]),
      .cout(cout_c[i])
    );
  end
endgenerate
// Connect carry chain
generate
  for (i = 1; i < WIDTH; i++) begin :gb_dc_ipu_array_divider_carry_chain
    assign cin_c[i] = cout_c[i - 1];
  end
endgenerate

endmodule
