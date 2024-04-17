module dc_ipu_mul_unit_carry_lookahead_adder(
  input wire [3:0] value_a,
  input wire [3:0] value_b,
  input wire c_i,
  output wire [3:0] sum,
  output wire c_o
);

wire [3:0] pro_c;
wire [3:0] gen_c;
wire [4:0] carry_c;
wire [3:0] sum_c;

dc_ipu_mul_unit_carry_lookahead_logic cla(
  .gen(gen_c),
  .pro(pro_c),
  .c_i(c_i),
  .carry(carry_c)
);

generate
  genvar i;
  for(i=0; i<4; i=i+1) begin : adder
    assign pro_c[i] = value_a[i] ^ value_b[i];
    assign gen_c[i] = value_a[i] & value_b[i];
    assign sum_c[i] = carry_c[i] ^ pro_c[i];
  end
endgenerate

assign sum = sum_c;
assign c_o = carry_c[4];

endmodule
