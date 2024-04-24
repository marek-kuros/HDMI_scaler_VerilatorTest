module dc_ipu_addr_compute_s3 #(
  parameter DATA_WIDTH,
  parameter FRACT_WIDTH,
  parameter INT_WIDTH
)(
  input wire clk,
  input wire nreset,
  input wire clr,

  input wire in_valid,
  output wire in_ready,
  input wire[DATA_WIDTH-1:0] in_data,

  output wire out_valid,
  input wire out_ready,
  output wire[INT_WIDTH-1:0] out_int,
  output wire[FRACT_WIDTH-1:0] out_fract
);

// Directly propagate 'ready' from sink
wire en = out_ready;
assign in_ready = out_ready;

dc_ipu_shr_pipeline_valid_flag u_valid_flag(
  .clk(clk),
  .nreset(nreset),
  .en(en),
  .clr(clr),

  .in_valid(in_valid),
  .out_valid(out_valid)
);

reg[DATA_WIDTH-1:0] data_r;
wire[DATA_WIDTH-1:0] data_nxt_c = in_data;
wire data_en_c = en;

always @(posedge clk or negedge nreset)
  if (!nreset)
    data_r <= '0;
  else if (data_en_c)
    data_r <= data_nxt_c;

// Add one - data is assumed to have FRACT_WIDTH wide fractional part
wire[DATA_WIDTH:0] data_minus_one_c = data_r - {1'b1, {FRACT_WIDTH{1'b0}}};

// Shift right
wire[DATA_WIDTH-1:0] tex_pos_c = data_minus_one_c[DATA_WIDTH:1];

// Split into fractional and integral parts
wire[INT_WIDTH-1:0] tex_pos_int_c = tex_pos_c[FRACT_WIDTH+INT_WIDTH-1:FRACT_WIDTH];
wire[FRACT_WIDTH-1:0] tex_pos_fract_c = tex_pos_c[FRACT_WIDTH-1:0];

assign out_int = tex_pos_int_c;
assign out_fract = tex_pos_fract_c;

endmodule