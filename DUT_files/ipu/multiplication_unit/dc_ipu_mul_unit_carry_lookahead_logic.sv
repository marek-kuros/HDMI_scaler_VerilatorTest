module dc_ipu_mul_unit_carry_lookahead_logic(
  input wire [3:0] gen,
  input wire [3:0] pro,
  input wire c_i,
  output wire [4:0] carry
);

wire [4:0] carry_c;

assign carry_c[0] = c_i;
assign carry_c[1] = gen[0] |
                  (pro[0] & c_i);
assign carry_c[2] = gen[1] |
                  (pro[0] & c_i & pro[1]) |
                  (pro[1] & gen[0]);
assign carry_c[3] = gen[2] | 
                  (pro[0] & c_i & pro[1] & pro[2]) |
                  (pro[1] & gen[0] & pro[2]) |
                  (pro[2] & gen[1]);
assign carry_c[4] = gen[3] | 
                  (pro[0] & c_i & pro[1] & pro[2] & pro[3]) |
                  (pro[1] & gen[0] & pro[2] & pro[3]) |
                  (pro[3] & gen[1] & pro[2]) |
                  (pro[3] & gen[2]);

assign carry = carry_c;

endmodule
