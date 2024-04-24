module dc_ipu_filter_cubic_weights #(
  parameter WEIGHT_WIDTH,
  parameter WEIGHT_FRACT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire en,

  input wire signed[WEIGHT_WIDTH-1:0] alpha,

  output wire signed[WEIGHT_WIDTH-1:0] out_weights[0:3]
);

// ------------------------------------------------------ Stage x-0 logic

wire signed[2*WEIGHT_WIDTH-1:0] alpha_sqr_wide_c = alpha * alpha;

// ------------------------------------------------------ Stage 0 registers

reg signed[WEIGHT_WIDTH-1:0] s0_alpha_r;
wire signed[WEIGHT_WIDTH-1:0] s0_alpha_nxt_c = alpha;
wire s0_alpha_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    s0_alpha_r <= '0;
  else if (s0_alpha_en_c)
    s0_alpha_r <= s0_alpha_nxt_c;

reg signed[WEIGHT_WIDTH-1:0] s0_alpha2_r;
wire signed[WEIGHT_WIDTH-1:0] s0_alpha2_nxt_c = alpha_sqr_wide_c[WEIGHT_FRACT_WIDTH +: WEIGHT_WIDTH];
wire s0_alpha2_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    s0_alpha2_r <= '0;
  else if (s0_alpha2_en_c)
    s0_alpha2_r <= s0_alpha2_nxt_c;

// ------------------------------------------------------ Stage 0-1 logic

wire signed[2*WEIGHT_WIDTH-1:0] alpha_cubed_wide_c = s0_alpha_r * s0_alpha2_r;
wire signed[WEIGHT_WIDTH-1:0] intermediate_weights_c[0:3];
assign intermediate_weights_c[0] = (s0_alpha2_r << 1) - s0_alpha_r;
assign intermediate_weights_c[1] = -(s0_alpha2_r << 2) - s0_alpha2_r + {2'd2, {WEIGHT_FRACT_WIDTH{1'b0}}};
assign intermediate_weights_c[2] = (s0_alpha2_r << 2) + s0_alpha_r;
assign intermediate_weights_c[3] = -s0_alpha2_r;

// ------------------------------------------------------ Stage 1 registers

reg[WEIGHT_WIDTH-1:0] s1_alpha3_r;
wire[WEIGHT_WIDTH-1:0] s1_alpha3_nxt_c = alpha_cubed_wide_c[WEIGHT_FRACT_WIDTH +: WEIGHT_WIDTH];
wire s1_alpha3_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    s1_alpha3_r <= '0;
  else if (s1_alpha3_en_c)
    s1_alpha3_r <= s1_alpha3_nxt_c;

reg signed[WEIGHT_WIDTH-1:0] s1_weights_r[0:3];
wire signed[WEIGHT_WIDTH-1:0] s1_weights_nxt_c[0:3];
assign s1_weights_nxt_c[0:3] = intermediate_weights_c;
wire s1_weights_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset) begin
    s1_weights_r[0] <= '0;
    s1_weights_r[1] <= '0;
    s1_weights_r[2] <= '0;
    s1_weights_r[3] <= '0;
  end
  else if (s1_weights_en_c)
    s1_weights_r <= s1_weights_nxt_c;

// ------------------------------------------------------ Stage 1-x logic

wire signed[WEIGHT_WIDTH-1:0] double_weights_c[0:3];
assign double_weights_c[0] = s1_weights_r[0] - s1_alpha3_r;
assign double_weights_c[1] = s1_weights_r[1] + s1_alpha3_r + (s1_alpha3_r <<< 1);
assign double_weights_c[2] = s1_weights_r[2] - s1_alpha3_r - (s1_alpha3_r <<< 1);
assign double_weights_c[3] = s1_weights_r[3] + s1_alpha3_r;

assign out_weights[0] = double_weights_c[0] >>> 1;
assign out_weights[1] = double_weights_c[1] >>> 1;
assign out_weights[2] = double_weights_c[2] >>> 1;
assign out_weights[3] = double_weights_c[3] >>> 1;

endmodule