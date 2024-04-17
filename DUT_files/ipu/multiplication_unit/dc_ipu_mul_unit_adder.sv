module dc_ipu_mul_unit_adder #( 
  parameter WIDTH,
  parameter NUM_OF_FAS = (WIDTH / 4)
)(
  input wire [WIDTH-1:0] value_a,
  input wire [WIDTH-1:0] value_b,
  input wire carry_i,
  output wire [WIDTH-1:0] sum,
  output wire carry_o
);

wire [NUM_OF_FAS:0] carry_c;
wire [WIDTH-1:0] sum_c;

assign carry_c[0] = carry_i;

generate
  genvar i;
  for(i=0; i<NUM_OF_FAS; i=i+1) begin : full_adder
    dc_ipu_mul_unit_carry_lookahead_adder fa(
      .value_a(value_a[(NUM_OF_FAS*i)+3:NUM_OF_FAS*i]),
      .value_b(value_b[(NUM_OF_FAS*i)+3:NUM_OF_FAS*i]),
      .c_i(carry_c[i]),
      .sum(sum_c[(NUM_OF_FAS*i)+3:NUM_OF_FAS*i]),
      .c_o(carry_c[i + 1])
    );
  end
endgenerate

assign carry_o = carry_c[NUM_OF_FAS];
assign sum = sum_c;

endmodule
