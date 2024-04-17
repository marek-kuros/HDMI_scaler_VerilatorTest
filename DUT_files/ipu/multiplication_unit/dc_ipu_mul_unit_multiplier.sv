module dc_ipu_mul_unit_multiplier#( 
  parameter WIDTH_A = 12,
  parameter WIDTH_B = 8
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire signed[WIDTH_A-1:0] value_a,
  input wire signed[WIDTH_B-1:0] value_b,

  output wire out_valid,
  input wire out_ready,
  output wire signed[WIDTH_B+WIDTH_A-1:0] result
);

wire buf_main_en;
wire buf_side_en;
wire buf_restore;

wire signed[WIDTH_A-1:0] buf_value_a_r;
wire signed[WIDTH_B-1:0] buf_value_b_r;

dc_ipu_shr_pipeline_logic u_pipeline_logic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .en(out_ready),
  .valid(out_valid),
  
  .in_valid(in_valid),
  .in_ready(in_ready),
  
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore)
);

dc_ipu_shr_pipeline_buffer #(.WIDTH(WIDTH_A)) u_pipeline_buffer_value_a(
  .clk(clk),
  .nreset(nreset),
  
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(value_a),
  .q(buf_value_a_r)
);

dc_ipu_shr_pipeline_buffer #(.WIDTH(WIDTH_B)) u_pipeline_buffer_value_b(
  .clk(clk),
  .nreset(nreset),
  
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(value_b),
  .q(buf_value_b_r)
);

wire [WIDTH_B-1:0] carry_c;
wire [WIDTH_B-1:0][WIDTH_A-1:0] sum_c;
wire [WIDTH_B-1:0][WIDTH_A-1:0] result_il_c;
wire [WIDTH_B+WIDTH_A-1:0] result_c;

assign carry_c[0] = 0;

dc_ipu_mul_unit_bank_and #( 
  .WIDTH(WIDTH_A)
)band(
  .value_a(buf_value_a_r),
  .value_b(buf_value_b_r[0]),
  .result_il(result_il_c[0])
);

assign sum_c[0] = result_il_c[0];

generate
  genvar i;
  for(i=1; i<WIDTH_B; i=i+1) begin : adder
    dc_ipu_mul_unit_bank_and #( 
      .WIDTH(WIDTH_A)
    )band(
      .value_a(buf_value_a_r),
      .value_b(buf_value_b_r[i]),
      .result_il(result_il_c[i])
    );
    dc_ipu_mul_unit_adder #( 
      .WIDTH(WIDTH_A)
    )add(
      .value_a(result_il_c[i]),
      .value_b({carry_c[i-1],sum_c[i-1][WIDTH_A-1:1]}),
      .carry_i(1'b0),
      .sum(sum_c[i]),
      .carry_o(carry_c[i])
    );
    assign result_c[i] = sum_c[i][0];
  end
endgenerate

assign result_c[0] = sum_c[0][0];
assign result_c[WIDTH_B+WIDTH_A-2:WIDTH_B-1] = sum_c[WIDTH_B-1];
assign result_c[WIDTH_B+WIDTH_A-1] = carry_c[WIDTH_B-1];

/*
  We're bypassing the multiplier here for two reasons:
  we need Quartus to instantiate hardware multiply blocks
  and we need signed multiplication because of cubic interpolation.
*/
// assign result = result_c;
assign result = buf_value_a_r * buf_value_b_r;

endmodule
