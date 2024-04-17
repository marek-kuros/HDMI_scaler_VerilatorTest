/*
  Array divider stage with registered A and B inputs.
  Outputs are not registered! Registered B value can
  be passed to the next stage from b_out output.
*/
module dc_ipu_array_divider_stage_seq #(
  parameter WIDTH
)
(
  input wire clk,
  input wire en,
  input wire nreset,
  
  input wire[WIDTH-1:0] a,
  input wire[WIDTH-1:0] b,
  output wire[WIDTH-1:0] r,
  output wire[WIDTH-1:0] b_out,
  output wire cout
);

// Registered A value
reg[WIDTH-1:0] a_r;
wire[WIDTH-1:0] a_nxt_c = a;
wire a_en_c = en;

// Registered B value
reg[WIDTH-1:0] b_r;
wire[WIDTH-1:0] b_nxt_c = b;
wire b_en_c = en;

// A register
always @(posedge clk or negedge nreset)
  if (!nreset)
    a_r <= '0;
  else if (a_en_c)
    a_r <= a_nxt_c;

// B register
always @(posedge clk or negedge nreset)
  if (!nreset)
    b_r <= '0;
  else if (b_en_c)
    b_r <= b_nxt_c;

// Combinational stage
dc_ipu_array_divider_stage_comb #(.WIDTH(WIDTH)) u_stage
(
  .a(a_r),
  .b(b_r),
  .r(r),
  .cout(cout),
  .cin(1'b1)
);

// B pass-through
assign b_out = b_r;

endmodule
