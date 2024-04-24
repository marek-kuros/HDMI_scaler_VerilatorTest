module dc_ipu_shr_pipeline_buffer #(
  parameter WIDTH
)
(
  input wire clk,
  input wire nreset,

  // Buffering control (from logic block)
  input wire buf_main_en,
  input wire buf_side_en,
  input wire buf_restore,

  // Data in/out  
  input wire[WIDTH-1:0] d,
  output wire[WIDTH-1:0] q
);

reg[WIDTH-1:0] side_r;
wire[WIDTH-1:0] side_nxt_c = d;
wire side_en_c = buf_side_en;

reg[WIDTH-1:0] data_r;
wire[WIDTH-1:0] data_nxt_c = buf_restore ? side_r : d;
wire data_en_c = buf_main_en;

assign q = data_r;

always @(posedge clk or negedge nreset)
  if (!nreset)
    side_r <= '0;
  else if (side_en_c)
    side_r <= side_nxt_c;

always @(posedge clk or negedge nreset)
  if (!nreset)
    data_r <= '0;
  else if (data_en_c)
    data_r <= data_nxt_c;

endmodule