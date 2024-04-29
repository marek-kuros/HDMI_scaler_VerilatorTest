module dc_ipu_gather #(
  parameter TEX_SIZE_WIDTH,
  parameter TEX_FRACT_WIDTH,
  parameter COLOR_WIDTH
)(
  clk,
  nreset,

  // Control interface
  ctl_start,
  ctl_abort,
  ctl_clamp_y,
  ctl_tex_width,

  // 4-lane Buffering Unit interface
  texel_valid,
  texel_ready,
  texel_data, 

  // Texture coordinate interface (main pipeline input)
  tc_valid,
  tc_ready,
  tc_int,
  tc_fract,

  // Texel output (main pipeline output)
  quad_valid,
  quad_ready,
  quad_data,
  quad_fract
);

localparam RGB_WIDTH = 3 * COLOR_WIDTH;
localparam CLAMP_CTL_WIDTH = 3;

input wire clk;
input wire nreset;

// Control interface
input wire ctl_start;
input wire ctl_abort;
input wire signed[CLAMP_CTL_WIDTH-1:0] ctl_clamp_y;
input wire[TEX_SIZE_WIDTH-1:0] ctl_tex_width;

// 4-lane Buffering Unit interface
input wire texel_valid;
output wire texel_ready;
input wire[RGB_WIDTH-1:0] texel_data[0:3]; 

// Texture coordinate interface (main pipeline input)
input wire tc_valid;
output wire tc_ready;
input wire signed[TEX_SIZE_WIDTH-1:0] tc_int;
input wire[TEX_FRACT_WIDTH-1:0] tc_fract;

// Texel output (main pipeline output)
output wire quad_valid;
input wire quad_ready;
output wire[RGB_WIDTH-1:0] quad_data[0:3][0:3];
output wire[TEX_FRACT_WIDTH-1:0] quad_fract;

// -------------------------------- Interface transfer signals

wire texel_transfer_c = texel_valid && texel_ready;

// -------------------------------- FSM definitions

localparam GATHER_FSM_STATE_WIDTH = 3;

localparam GATHER_FSM_IDLE       = 0;
localparam GATHER_FSM_PREFETCH_0 = 1;
localparam GATHER_FSM_PREFETCH_1 = 2;
localparam GATHER_FSM_PREFETCH_2 = 3;
localparam GATHER_FSM_PREFETCH_3 = 4;
localparam GATHER_FSM_PREFETCH_4 = 5;
localparam GATHER_FSM_START      = 6;
localparam GATHER_FSM_ACTIVE     = 7;

reg[GATHER_FSM_STATE_WIDTH-1:0] gather_fsm_r;
reg[GATHER_FSM_STATE_WIDTH-1:0] gather_fsm_nxt_c;
wire gather_fsm_en_c = 1'b1;

always @(posedge clk or negedge nreset)
  if (!nreset)
    gather_fsm_r <= '0;
  else if (gather_fsm_en_c)
    gather_fsm_r <= gather_fsm_nxt_c;

// -------------------------------- Control registers

// Texture width register
reg[TEX_SIZE_WIDTH-1:0] tex_width_r;
wire[TEX_SIZE_WIDTH-1:0] tex_width_nxt_c = ctl_tex_width;
wire tex_width_en_c = ctl_start;

always @(posedge clk or negedge nreset)
  if (!nreset)
    tex_width_r <= '0;
  else if (tex_width_en_c)
    tex_width_r <= tex_width_nxt_c;

// Vertical clamping control register
reg signed[CLAMP_CTL_WIDTH-1:0] clamp_y_r;
wire signed[CLAMP_CTL_WIDTH-1:0] clamp_y_nxt_c = ctl_clamp_y;
wire clamp_y_en_c = ctl_start;

always @(posedge clk or negedge nreset)
  if (!nreset)
    clamp_y_r <= '0;
  else if (clamp_y_en_c)
    clamp_y_r <= clamp_y_nxt_c;

// -------------------------------- Counters

// Texture x coordinate counter (relative to the (1, 1) texel in the matrix)
// This counter lags behind the requested coordinate stored in buf_tc_int_r
// Whenever new data is loaded into the matrix, this counter is incremented
wire tex_x_inc_c;
reg signed[TEX_SIZE_WIDTH-1:0] tex_x_r;
wire signed[TEX_SIZE_WIDTH-1:0] tex_x_nxt_c = tex_x_inc_c ? (tex_x_r + 1'b1) : -5'd3; // Reset to -3 during START!
wire tex_x_en_c = tex_x_inc_c || (gather_fsm_r == GATHER_FSM_START);

always @(posedge clk or negedge nreset)
  if (!nreset)
    tex_x_r <= '0;
  else if (tex_x_en_c)
    tex_x_r <= tex_x_nxt_c;

// Texel transfer counter
// Used to determine when to start clamping to the right edge
wire texel_transfer_cnt_inc_c = texel_transfer_c;
reg[TEX_SIZE_WIDTH-1:0] texel_transfer_cnt_r;
wire[TEX_SIZE_WIDTH-1:0] texel_transfer_cnt_nxt_c = texel_transfer_cnt_inc_c ? (texel_transfer_cnt_r + 1'b1) : '0;
wire texel_transfer_cnt_en_c = texel_transfer_cnt_inc_c || ctl_start;

always @(posedge clk or negedge nreset)
  if (!nreset)
    texel_transfer_cnt_r <= '0;
  else if (texel_transfer_cnt_en_c)
    texel_transfer_cnt_r <= texel_transfer_cnt_nxt_c;

// -------------------------------- Pipeline buffers

// Pipeline control signals
wire buf_tc_valid;
wire buf_clr = ctl_start;
wire buf_main_en;
wire buf_side_en;
wire buf_restore;

// Buffered texture coordinates
wire signed[TEX_SIZE_WIDTH-1:0] buf_tc_int_r;
wire[TEX_FRACT_WIDTH-1:0] buf_tc_fract_r;

// Indicates that there are no more texels to fetch in this line
wire tex_read_end_c = (texel_transfer_cnt_r == tex_width_r);

// Shifts the quad_c one pixel ahead
wire quad_shift_c = (buf_tc_int_r > tex_x_r) && buf_tc_valid;

// Indicates whether we have data for the tex_x_r address in the texel matrix
wire quad_ok_c = (tex_x_r + quad_shift_c == buf_tc_int_r);

// Determines whether the texture address interface will be ready in the
// next cycle.
wire en_c = (gather_fsm_r == GATHER_FSM_ACTIVE)
            && (buf_tc_valid ? (quad_ready && quad_ok_c) : 1'b1);

dc_ipu_shr_pipeline_logic u_pipeline_logic(
  .clk(clk),
  .nreset(nreset),
  .clr(buf_clr),

  .in_valid(tc_valid),
  .in_ready(tc_ready),

  .en(en_c),
  .valid(buf_tc_valid),
  
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore)
);

dc_ipu_shr_pipeline_buffer #(.WIDTH(TEX_SIZE_WIDTH)) u_pipeline_buffer_tc_int(
  .clk(clk),
  .nreset(nreset),
  
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(tc_int),
  .q(buf_tc_int_r)
);

dc_ipu_shr_pipeline_buffer #(.WIDTH(TEX_FRACT_WIDTH)) u_pipeline_buffer_tc_fract(
  .clk(clk),
  .nreset(nreset),
  
  .buf_main_en(buf_main_en),
  .buf_side_en(buf_side_en),
  .buf_restore(buf_restore),

  .d(tc_fract),
  .q(buf_tc_fract_r)
);

// -------------------------------- Vertical clamping

// Vertical clamping logic at the texel inputs
wire[RGB_WIDTH-1:0] clamped_data_c[0:3];
assign clamped_data_c[0] = 
  (clamp_y_r == -3) ? texel_data[0] : 
  (clamp_y_r == -2) ? texel_data[0] :
  (clamp_y_r == -1) ? texel_data[0] :
  (clamp_y_r ==  0) ? texel_data[0] :
  (clamp_y_r ==  1) ? texel_data[1] :
  (clamp_y_r ==  2) ? texel_data[2] :
  (clamp_y_r ==  3) ? texel_data[3] : 'x; // This may be a bad idea, but I'm not sure

assign clamped_data_c[1] = 
  (clamp_y_r == -3) ? texel_data[0] : 
  (clamp_y_r == -2) ? texel_data[0] :
  (clamp_y_r == -1) ? texel_data[0] :
  (clamp_y_r ==  0) ? texel_data[1] :
  (clamp_y_r ==  1) ? texel_data[2] :
  (clamp_y_r ==  2) ? texel_data[3] :
  (clamp_y_r ==  3) ? texel_data[3] : 'x;

assign clamped_data_c[2] =
  (clamp_y_r == -3) ? texel_data[0] : 
  (clamp_y_r == -2) ? texel_data[0] :
  (clamp_y_r == -1) ? texel_data[1] :
  (clamp_y_r ==  0) ? texel_data[2] :
  (clamp_y_r ==  1) ? texel_data[3] :
  (clamp_y_r ==  2) ? texel_data[3] :
  (clamp_y_r ==  3) ? texel_data[3] : 'x;

assign clamped_data_c[3] = 
  (clamp_y_r == -3) ? texel_data[0] : 
  (clamp_y_r == -2) ? texel_data[1] :
  (clamp_y_r == -1) ? texel_data[2] :
  (clamp_y_r ==  0) ? texel_data[3] :
  (clamp_y_r ==  1) ? texel_data[3] :
  (clamp_y_r ==  2) ? texel_data[3] :
  (clamp_y_r ==  3) ? texel_data[3] : 'x;


// -------------------------------- Texel matrix

// This signal indicates that the matrix is being filled with repeated pixel data
wire matrix_prefill_c = 
       (gather_fsm_r == GATHER_FSM_PREFETCH_1)
    || (gather_fsm_r == GATHER_FSM_PREFETCH_2)
    || (gather_fsm_r == GATHER_FSM_PREFETCH_3)
    || (gather_fsm_r == GATHER_FSM_PREFETCH_4);

// Determines whether the matrix is being fed from itself
wire matrix_feedback_en_c = matrix_prefill_c || tex_read_end_c;

reg[RGB_WIDTH-1:0] matrix_r[0:4][0:3];
reg[RGB_WIDTH-1:0] matrix_nxt_c[0:4][0:3];
wire matrix_en_c = matrix_prefill_c || (tex_read_end_c ? quad_shift_c : texel_transfer_c);

// Increment the x counter when data is loaded during the ACTIVE state
assign tex_x_inc_c = matrix_en_c && (gather_fsm_r == GATHER_FSM_ACTIVE);

always @(posedge clk or negedge nreset)
  if (!nreset) begin
    for (byte i=0; i<5; i=i+1) begin
      for (byte j=0; j<4; j=j+1) begin
        matrix_r[i][j] <= '0;
      end
        //matrix_r <= '{default: '0};
    end
  end
  else if (matrix_en_c)
    matrix_r <= matrix_nxt_c;

// Matrix shifts data to the left
always_comb begin
  for (int y = 0; y < 4; y = y + 1) begin
    for (int x = 0; x < 4; x = x + 1) begin
      matrix_nxt_c[x][y] <= matrix_r[x + 1][y];
    end
    matrix_nxt_c[4][y] <= matrix_feedback_en_c ? matrix_r[4][y] : clamped_data_c[y];
  end
end

// -------------------------------- Horizontal clamping

// Portion of the matrix selected depending on whether next pixel column
// should be fetched already
wire[RGB_WIDTH-1:0] quad_c[0:3][0:3];
assign quad_c[0] = quad_shift_c ? matrix_r[1] : matrix_r[0];
assign quad_c[1] = quad_shift_c ? matrix_r[2] : matrix_r[1];
assign quad_c[2] = quad_shift_c ? matrix_r[3] : matrix_r[2];
assign quad_c[3] = quad_shift_c ? matrix_r[4] : matrix_r[3];

// -------------------------------- Texel data input

// If possible, fetch new data when quad_shift_c is asserted
assign texel_ready = 
       (gather_fsm_r == GATHER_FSM_PREFETCH_0)
    || (buf_tc_valid && quad_shift_c && !tex_read_end_c);

// -------------------------------- Texel quad ouptut

assign quad_data = quad_c;
assign quad_fract = buf_tc_fract_r;
assign quad_valid = buf_tc_valid && quad_ok_c && (gather_fsm_r == GATHER_FSM_ACTIVE);

// -------------------------------- FSM logic

always_comb
  case (gather_fsm_r)

    // Waiting for data on the control interface
    GATHER_FSM_IDLE:
      gather_fsm_nxt_c <= ctl_start ? GATHER_FSM_PREFETCH_0 : GATHER_FSM_IDLE;

    // The 1st prefetching state loads the first column of pixels from the BU
    GATHER_FSM_PREFETCH_0:
      gather_fsm_nxt_c <= texel_transfer_c ? GATHER_FSM_PREFETCH_1 : GATHER_FSM_PREFETCH_0;

    // Subsequent prefetching states replicate the data
    GATHER_FSM_PREFETCH_1:
      gather_fsm_nxt_c <= GATHER_FSM_PREFETCH_2;

    GATHER_FSM_PREFETCH_2:
      gather_fsm_nxt_c <= GATHER_FSM_PREFETCH_3;

    GATHER_FSM_PREFETCH_3:
      gather_fsm_nxt_c <= GATHER_FSM_PREFETCH_4;

    GATHER_FSM_PREFETCH_4:
      gather_fsm_nxt_c <= GATHER_FSM_START;

    // Intermediate state for clearing counters etc.
    GATHER_FSM_START:
      gather_fsm_nxt_c <= GATHER_FSM_ACTIVE;

    // Active until terminating signal is received
    GATHER_FSM_ACTIVE:
      gather_fsm_nxt_c <= ctl_abort ? GATHER_FSM_IDLE : GATHER_FSM_ACTIVE; 

    default:
      gather_fsm_nxt_c <= 'x;

  endcase

endmodule