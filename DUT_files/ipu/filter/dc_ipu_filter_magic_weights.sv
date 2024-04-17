module dc_ipu_filter_magic_weights #(
  parameter WEIGHT_WIDTH,
  parameter WEIGHT_FRACT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire en,

  input wire signed[WEIGHT_WIDTH-1:0] alpha,

  output wire signed[WEIGHT_WIDTH-1:0] out_weights[0:3]
);

reg signed[WEIGHT_WIDTH-1:0] alpha_r;
wire signed[WEIGHT_WIDTH-1:0] alpha_nxt_c = alpha;
wire alpha_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    alpha_r <= '0;
  else if (alpha_en_c)
    alpha_r <= alpha_nxt_c;

wire signed[2*WEIGHT_WIDTH-1:0] alpha_sqr_wide_c = alpha * alpha;

reg signed[WEIGHT_WIDTH-1:0] alpha2_r;
wire signed[WEIGHT_WIDTH-1:0] alpha2_nxt_c = alpha_sqr_wide_c[WEIGHT_FRACT_WIDTH +: WEIGHT_WIDTH];
wire alpha2_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    alpha2_r <= '0;
  else if (alpha2_en_c)
    alpha2_r <= alpha2_nxt_c;

wire signed[WEIGHT_WIDTH-1:0] double_weights_1_c[0:3];
assign double_weights_1_c[0] = '0;
assign double_weights_1_c[1] = alpha2_r - alpha_r - (alpha_r << 1) + {4'd9, {(WEIGHT_FRACT_WIDTH - 2){1'b0}}};
assign double_weights_1_c[2] = -(alpha2_r << 1) + (alpha_r << 2)   - {4'd2, {(WEIGHT_FRACT_WIDTH - 2){1'b0}}};
assign double_weights_1_c[3] = alpha2_r - alpha_r                  + {4'd1, {(WEIGHT_FRACT_WIDTH - 2){1'b0}}};

wire signed[WEIGHT_WIDTH-1:0] double_weights_2_c[0:3];
assign double_weights_2_c[0] = alpha2_r - alpha_r                + {4'd1, {(WEIGHT_FRACT_WIDTH - 2){1'b0}}};
assign double_weights_2_c[1] = -(alpha2_r << 1)                  + {4'd6, {(WEIGHT_FRACT_WIDTH - 2){1'b0}}};
assign double_weights_2_c[2] = alpha2_r + alpha_r                + {4'd1, {(WEIGHT_FRACT_WIDTH - 2){1'b0}}};
assign double_weights_2_c[3] = '0;

wire weight_sel_c = alpha_r[WEIGHT_FRACT_WIDTH-1];
assign out_weights[0] = weight_sel_c ? (double_weights_1_c[0] >> 1) : (double_weights_2_c[0] >> 1);
assign out_weights[1] = weight_sel_c ? (double_weights_1_c[1] >> 1) : (double_weights_2_c[1] >> 1);
assign out_weights[2] = weight_sel_c ? (double_weights_1_c[2] >> 1) : (double_weights_2_c[2] >> 1);
assign out_weights[3] = weight_sel_c ? (double_weights_1_c[3] >> 1) : (double_weights_2_c[3] >> 1);

endmodule
