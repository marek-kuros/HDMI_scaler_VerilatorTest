module dc_ipu_mul_unit_bank_and #( 
  parameter WIDTH
)(
  input wire [WIDTH-1:0] value_a,
  input wire value_b,
  output wire [WIDTH-1:0] result_il
);

wire [WIDTH-1:0] result_il_c;

generate 
  genvar i;
  for(i=0; i<WIDTH; i=i+1) begin : band
    assign result_il_c[i] = value_b & value_a[i];
  end
endgenerate

assign result_il = result_il_c;

endmodule
