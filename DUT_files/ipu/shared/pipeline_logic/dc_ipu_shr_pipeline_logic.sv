module dc_ipu_shr_pipeline_logic(
  input wire clk,
  input wire nreset,
  input wire clr,

  // Block internal
  input wire en,
  output wire valid,

  // To previous pipeline block
  input wire in_valid,
  output wire in_ready,

  // To buffers
  output wire buf_main_en,
  output wire buf_side_en,
  output wire buf_restore
);

// Buffered ready signal
reg in_ready_r;
wire in_ready_nxt_c = en;
wire in_ready_en_c = 1;

// Side valid register
reg side_valid_r;
wire side_valid_nxt_c;
wire side_valid_en_c;

// Output valid register
reg valid_r;
wire valid_nxt_c;
wire valid_en_c;

// Internal stall & resume signals
wire stall_c = in_ready & !en;
wire resume_c = !in_ready & en;

// Register whether valid data is incoming on stall
// No need to clear the flag - the register is only read on resume
assign side_valid_nxt_c = !clr & (in_valid);
assign side_valid_en_c = stall_c | clr;

// The main valid flag
assign valid_nxt_c = !clr & (resume_c ? side_valid_r : in_valid);
assign valid_en_c = en | clr;

// To previous block
assign in_ready = in_ready_r;

// Buffer control signals
assign buf_side_en = stall_c & in_valid;      // Write side buffer only when pipeline stalls and valid data is incoming
assign buf_restore = resume_c & side_valid_r; // Only restore valid data on resume
assign buf_main_en = en & valid_nxt_c;        // Don't update main buffer unless the new data is actually valid

// For this block
assign valid = valid_r;

always @(posedge clk or negedge nreset)
  if (!nreset)
    in_ready_r <= 1'b0;
  else if (in_ready_en_c)
    in_ready_r <= in_ready_nxt_c;

always @(posedge clk or negedge nreset)
  if (!nreset)
    side_valid_r <= 1'b0;
  else if (side_valid_en_c)
    side_valid_r <= side_valid_nxt_c;

always @(posedge clk or negedge nreset)
  if (!nreset)
    valid_r <= 1'b0;
  else if (valid_en_c)
    valid_r <= valid_nxt_c;

endmodule
