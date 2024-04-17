module dc_image_processing_unit #(
  parameter SCR_SIZE_WIDTH,
  parameter TEX_SIZE_WIDTH
)(
  clk,
  nreset,

  // Status signals
  status_done,

  // MCL interface
  ctl_valid,
  ctl_ready,
  ctl_image_offset_x,
  ctl_image_offset_y,
  ctl_image_width,
  ctl_image_height,
  ctl_screen_width,
  ctl_screen_y,
  ctl_tex_width,
  ctl_tex_height,
  ctl_scale_method,
  ctl_border_color,

  // MCL texture data request interface
  tex_request_valid,
  tex_request_ready,
  tex_request_y,

  // Texel data interface (to the buffering unit)
  texel_valid,
  texel_ready,
  texel_data0,
  texel_data1,
  texel_data2,
  texel_data3,

  // Pixel data interface (to screen/compositor unit)
  pixel_valid,
  pixel_ready,
  pixel_data, 
  pixel_border
);

localparam SCALE_METHOD_WIDTH = 2;
localparam TEX_FRACT_WIDTH = 12;
localparam COLOR_WIDTH = 8;
localparam RGB_WIDTH = 3 * COLOR_WIDTH;
localparam CLAMP_CTL_WIDTH = 3;

input wire clk;
input wire nreset;

// Status signals
output wire status_done;

// MCL interface
input wire ctl_valid;
output wire ctl_ready;
input wire[SCR_SIZE_WIDTH-1:0] ctl_image_offset_x;
input wire[SCR_SIZE_WIDTH-1:0] ctl_image_offset_y;
input wire[SCR_SIZE_WIDTH-1:0] ctl_image_width;
input wire[SCR_SIZE_WIDTH-1:0] ctl_image_height;
input wire[SCR_SIZE_WIDTH-1:0] ctl_screen_width;
input wire[SCR_SIZE_WIDTH-1:0] ctl_screen_y;
input wire[SCR_SIZE_WIDTH-1:0] ctl_tex_width;
input wire[SCR_SIZE_WIDTH-1:0] ctl_tex_height;
input wire[SCALE_METHOD_WIDTH-1:0] ctl_scale_method;
input wire[RGB_WIDTH-1:0] ctl_border_color;

// MCL texture data request interface
output wire tex_request_valid;
input wire tex_request_ready;
output wire[TEX_SIZE_WIDTH-1:0] tex_request_y;

// Texel data interface (to the buffering unit)
input wire texel_valid;
output wire texel_ready;
input wire[RGB_WIDTH-1:0] texel_data0;
input wire[RGB_WIDTH-1:0] texel_data1;
input wire[RGB_WIDTH-1:0] texel_data2;
input wire[RGB_WIDTH-1:0] texel_data3;

// Pixel data interface (to screen/compositor unit)
output wire pixel_valid;
input wire pixel_ready;
output wire[RGB_WIDTH-1:0] pixel_data; 
output wire pixel_border;

  
// -------------------------------- FSM definitions

localparam IPU_FSM_STATE_WIDTH = 4;

localparam IPU_FSM_IDLE                = 4'd0;
localparam IPU_FSM_INIT                = 4'd1;
localparam IPU_FSM_Y_HIT_MISS          = 4'd2;
localparam IPU_FSM_START_COMPUTE_TEX_Y = 4'd3;
localparam IPU_FSM_WAIT_COMPUTE_TEX_Y  = 4'd4;
localparam IPU_FSM_WAIT_TEX_REQUEST    = 4'd5;
localparam IPU_FSM_START_EMPTY_LINE    = 4'd6;
localparam IPU_FSM_ACTIVE_EMPTY_LINE   = 4'd7;
localparam IPU_FSM_START               = 4'd8;
localparam IPU_FSM_WAIT_FILL           = 4'd9;
localparam IPU_FSM_ACTIVE              = 4'd10;
localparam IPU_FSM_DONE                = 4'd11;

// FSM state reg
reg[IPU_FSM_STATE_WIDTH-1:0] ipu_fsm_r;
reg[IPU_FSM_STATE_WIDTH-1:0] ipu_fsm_nxt_c;
wire ipu_fsm_en_c = 1'b1;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    ipu_fsm_r <= '0;
  else if (ipu_fsm_en_c)
    ipu_fsm_r <= ipu_fsm_nxt_c;

// -------------------------------- Signals

// Output control signals
assign ctl_ready = (ipu_fsm_r == IPU_FSM_IDLE);
assign tex_request_valid = (ipu_fsm_r == IPU_FSM_WAIT_TEX_REQUEST);
assign status_done = (ipu_fsm_r == IPU_FSM_DONE);

// Transfer signals
wire ctl_transfer_c = ctl_valid & ctl_ready;
wire tex_request_transfer_c = tex_request_valid & tex_request_ready;
wire texel_transfer_c = texel_valid & texel_ready;
wire pixel_transfer_c = pixel_valid & pixel_ready;

// Pipeline control signals
wire scaler_pipeline_active_c = (ipu_fsm_r == IPU_FSM_ACTIVE) || (ipu_fsm_r == IPU_FSM_WAIT_FILL);
wire scaler_pipeline_clr_c = (ipu_fsm_r == IPU_FSM_START);

// -------------------------------- Control regsiters (updated from the control interface)

reg[SCR_SIZE_WIDTH-1:0] image_offset_x_r;
wire[SCR_SIZE_WIDTH-1:0] image_offset_x_nxt_c = ctl_image_offset_x;
wire image_offset_x_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    image_offset_x_r <= '0;
  else if (image_offset_x_en_c)
    image_offset_x_r <= image_offset_x_nxt_c;

reg[SCR_SIZE_WIDTH-1:0] image_offset_y_r;
wire[SCR_SIZE_WIDTH-1:0] image_offset_y_nxt_c = ctl_image_offset_y;
wire image_offset_y_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    image_offset_y_r <= '0;
  else if (image_offset_y_en_c)
    image_offset_y_r <= image_offset_y_nxt_c;

reg[SCR_SIZE_WIDTH-1:0] image_width_r;
wire[SCR_SIZE_WIDTH-1:0] image_width_nxt_c = ctl_image_width;
wire image_width_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    image_width_r <= '0;
  else if (image_width_en_c)
    image_width_r <= image_width_nxt_c;

reg[SCR_SIZE_WIDTH-1:0] image_height_r;
wire[SCR_SIZE_WIDTH-1:0] image_height_nxt_c = ctl_image_height;
wire image_height_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    image_height_r <= '0;
  else if (image_height_en_c)
    image_height_r <= image_height_nxt_c;

reg[SCR_SIZE_WIDTH-1:0] screen_width_r;
wire[SCR_SIZE_WIDTH-1:0] screen_width_nxt_c = ctl_screen_width;
wire screen_width_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    screen_width_r <= '0;
  else if (screen_width_en_c)
    screen_width_r <= screen_width_nxt_c;

reg[SCR_SIZE_WIDTH-1:0] screen_y_r;
wire[SCR_SIZE_WIDTH-1:0] screen_y_nxt_c = ctl_screen_y;
wire screen_y_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    screen_y_r <= '0;
  else if (screen_y_en_c)
    screen_y_r <= screen_y_nxt_c;

reg[SCR_SIZE_WIDTH-1:0] tex_width_r;
wire[SCR_SIZE_WIDTH-1:0] tex_width_nxt_c = ctl_tex_width;
wire tex_width_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    tex_width_r <= '0;
  else if (tex_width_en_c)
    tex_width_r <= tex_width_nxt_c;

reg[SCR_SIZE_WIDTH-1:0] tex_height_r;
wire[SCR_SIZE_WIDTH-1:0] tex_height_nxt_c = ctl_tex_height;
wire tex_height_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    tex_height_r <= '0;
  else if (tex_height_en_c)
    tex_height_r <= tex_height_nxt_c;

reg[SCALE_METHOD_WIDTH-1:0] scale_method_r;
wire[SCALE_METHOD_WIDTH-1:0] scale_method_nxt_c = ctl_scale_method;
wire scale_method_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    scale_method_r <= '0;
  else if (scale_method_en_c)
    scale_method_r <= scale_method_nxt_c;

reg[23:0] border_color_r;
wire[23:0] border_color_nxt_c = ctl_border_color;
wire border_color_en_c = ctl_transfer_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    border_color_r <= '0;
  else if (border_color_en_c)
    border_color_r <= border_color_nxt_c;

// -------------------------------- Position & transfer counters/registers

// X coordinate in the screen space
// Incremented on output pixel transfers
// Reset during INIT
wire screen_x_inc_c = pixel_transfer_c;
reg[SCR_SIZE_WIDTH-1:0] screen_x_r;
wire[SCR_SIZE_WIDTH-1:0] screen_x_nxt_c = screen_x_inc_c ? (screen_x_r + 1'b1) : '0;
wire screen_x_en_c = (ipu_fsm_r == IPU_FSM_INIT) | screen_x_inc_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    screen_x_r <= '0;
  else if (screen_x_en_c)
    screen_x_r <= screen_x_nxt_c;

// X coordinate in the image space
// Incremented on address compute input transfers
// Reset during INIT
wire image_x_inc_c;
reg[SCR_SIZE_WIDTH-1:0] image_x_r;
wire[SCR_SIZE_WIDTH-1:0] image_x_nxt_c = image_x_inc_c ? (image_x_r + 1'b1) : '0;
wire image_x_en_c = (ipu_fsm_r == IPU_FSM_INIT) || image_x_inc_c;

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    image_x_r <= '0;
  else if (image_x_en_c)
    image_x_r <= image_x_nxt_c;

// Y coordinate in the image space
// Updated during INIT
reg[SCR_SIZE_WIDTH-1:0] image_y_r;
wire[SCR_SIZE_WIDTH-1:0] image_y_nxt_c = screen_y_r - image_offset_y_r;
wire image_y_en_c = (ipu_fsm_r == IPU_FSM_INIT);

always_ff @(posedge clk or negedge nreset)
  if (!nreset)
    image_y_r <= '0;
  else if (image_y_en_c)
    image_y_r <= image_y_nxt_c;

// -------------------------------- Address compute block

wire addr_compute_xy_sel_c = (ipu_fsm_r == IPU_FSM_START_COMPUTE_TEX_Y);
wire addr_compute_clr_c = (ipu_fsm_r == IPU_FSM_INIT) || scaler_pipeline_clr_c;

wire addr_compute_in_valid_c = (ipu_fsm_r == IPU_FSM_START_COMPUTE_TEX_Y) || scaler_pipeline_active_c;
wire addr_compute_in_ready;
wire addr_compute_in_transfer_c = addr_compute_in_valid_c && addr_compute_in_ready;
wire[SCR_SIZE_WIDTH-1:0] addr_compute_in_c = addr_compute_xy_sel_c ? image_y_r : image_x_r;
wire[SCR_SIZE_WIDTH-1:0] addr_compute_image_size_c = addr_compute_xy_sel_c ? image_height_r : image_width_r;
wire[TEX_SIZE_WIDTH-1:0] addr_compute_tex_size_c = addr_compute_xy_sel_c ? tex_height_r : tex_width_r;

wire addr_compute_out_valid;
wire addr_compute_out_ready_c;
wire addr_compute_out_transfer_c = addr_compute_out_valid && addr_compute_out_ready_c;
wire signed[TEX_SIZE_WIDTH-1:0] addr_compute_out_int;
wire[TEX_FRACT_WIDTH-1:0] addr_compute_out_fract;

// Increment the image_x counter
assign image_x_inc_c = scaler_pipeline_active_c && addr_compute_in_transfer_c;

dc_ipu_addr_compute #(
  .IMG_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .TEX_SIZE_WIDTH(TEX_SIZE_WIDTH),
  .TEX_FRACT_WIDTH(TEX_FRACT_WIDTH)
)
u_addr_compute(
  .clk(clk),
  .nreset(nreset),
  .clr(addr_compute_clr_c),

  .in_valid(addr_compute_in_valid_c),
  .in_ready(addr_compute_in_ready),
  .x(addr_compute_in_c),
  .img_size(addr_compute_image_size_c),
  .tex_size(addr_compute_tex_size_c),

  .out_valid(addr_compute_out_valid),
  .out_ready(addr_compute_out_ready_c),
  .tex_addr(addr_compute_out_int),
  .tex_addr_fract(addr_compute_out_fract)
);

// Integral part of the texture coordinate
// Updated after y tex coordinate is computed
reg signed[TEX_SIZE_WIDTH-1:0] tex_y_int_r;
wire signed[TEX_SIZE_WIDTH-1:0] tex_y_int_nxt_c = addr_compute_out_int;
wire tex_y_int_en_c = (ipu_fsm_r == IPU_FSM_WAIT_COMPUTE_TEX_Y) & addr_compute_out_transfer_c;

always @(posedge clk or negedge nreset)
  if (!nreset)
    tex_y_int_r <= '0;
  else if (tex_y_int_en_c)
    tex_y_int_r <= tex_y_int_nxt_c;

// Fractional part of the texture coordinate
// Updated after y tex coordinate is computed
reg[TEX_FRACT_WIDTH-1:0] tex_y_fract_r;
wire[TEX_FRACT_WIDTH-1:0] tex_y_fract_nxt_c = addr_compute_out_fract;
wire tex_y_fract_en_c = tex_y_int_en_c;

always @(posedge clk or negedge nreset)
  if (!nreset)
    tex_y_fract_r <= '0;
  else if (tex_y_fract_en_c)
    tex_y_fract_r <= tex_y_fract_nxt_c;

// -------------------------------- Image & screen boundaries

wire[SCR_SIZE_WIDTH-1:0] image_end_x_c = image_offset_x_r + image_width_r;
wire[SCR_SIZE_WIDTH-1:0] image_end_y_c = image_offset_y_r + image_height_r;
wire image_hit_x_c = (screen_x_r >= image_offset_x_r) & (screen_x_r < image_end_x_c);
wire image_hit_y_c = (screen_y_r >= image_offset_y_r) & (screen_y_r < image_end_y_c);
wire image_hit_c = image_hit_x_c & image_hit_y_c;

wire[SCR_SIZE_WIDTH-1:0] screen_max_x_c = screen_width_r - 1'b1;
wire last_pixel_transfer_c = screen_x_r == screen_max_x_c;

// -------------------------------- Texture Y clamping logic

wire signed[TEX_SIZE_WIDTH-1:0] tex_y_max_c = tex_height_r - 3'd4;
wire signed[TEX_SIZE_WIDTH-1:0] tex_y_minus_one_c = tex_y_int_r - 1'd1;
wire tex_y_below_min_c = tex_y_minus_one_c[TEX_SIZE_WIDTH - 1];
wire tex_y_above_max_c = tex_y_minus_one_c > tex_y_max_c;
wire[TEX_SIZE_WIDTH-1:0] tex_y_clamped_c = tex_y_below_min_c ? '0 :
                                           tex_y_above_max_c ? tex_y_max_c :
                                           tex_y_minus_one_c;

wire signed[CLAMP_CTL_WIDTH-1:0] clamp_y_c = tex_y_minus_one_c[CLAMP_CTL_WIDTH-1:0] - tex_y_clamped_c[CLAMP_CTL_WIDTH-1:0];
assign tex_request_y = tex_y_clamped_c;


// -------------------------------- Texel gather pipeline 

wire[RGB_WIDTH-1:0] gather_filter_texel_quad[0:3][0:3];
wire[TEX_FRACT_WIDTH-1:0] gather_filter_coeff_x;

wire gather_ctl_start_c = (ipu_fsm_r == IPU_FSM_START);
wire gather_ctl_abort_c = (ipu_fsm_r == IPU_FSM_DONE);

wire[RGB_WIDTH-1:0] gather_texel_data[0:3];
assign gather_texel_data[0] = texel_data0;
assign gather_texel_data[1] = texel_data1;
assign gather_texel_data[2] = texel_data2;
assign gather_texel_data[3] = texel_data3;

wire gather_in_valid_c = scaler_pipeline_active_c && addr_compute_out_valid;
wire gather_in_ready;
wire signed[TEX_SIZE_WIDTH-1:0] gather_in_tc_int = addr_compute_out_int;
wire[TEX_FRACT_WIDTH-1:0] gather_in_tc_fract = addr_compute_out_fract;

wire gather_filter_valid;
wire gather_filter_ready;

dc_ipu_gather #(
  .TEX_SIZE_WIDTH(TEX_SIZE_WIDTH),
  .TEX_FRACT_WIDTH(TEX_FRACT_WIDTH),
  .COLOR_WIDTH(COLOR_WIDTH)
)
u_gather(
  .clk(clk),
  .nreset(nreset),
  
  .ctl_start(gather_ctl_start_c),
  .ctl_abort(gather_ctl_abort_c),
  .ctl_clamp_y(clamp_y_c),
  .ctl_tex_width(tex_width_r),

  .texel_valid(texel_valid),
  .texel_ready(texel_ready),
  .texel_data(gather_texel_data),

  .tc_valid(gather_in_valid_c),
  .tc_ready(gather_in_ready),
  .tc_int(gather_in_tc_int),
  .tc_fract(gather_in_tc_fract),

  .quad_valid(gather_filter_valid),
  .quad_ready(gather_filter_ready),
  .quad_data(gather_filter_texel_quad),
  .quad_fract(gather_filter_coeff_x)
);

// 'Ready' signal for addr compute depends on the gather block and the FSM
assign addr_compute_out_ready_c = 
  scaler_pipeline_active_c ? gather_in_ready :                                                // Forward 'ready'
  ((ipu_fsm_r == IPU_FSM_START_COMPUTE_TEX_Y) || (ipu_fsm_r == IPU_FSM_WAIT_COMPUTE_TEX_Y));  // Y address compute

// -------------------------------- Texture filtering pipeline

wire filter_clr_c = scaler_pipeline_clr_c;

wire filter_out_valid;
wire filter_out_ready;
wire[RGB_WIDTH-1:0] filter_out_pixel;

dc_ipu_filter #(
  .COEFF_WIDTH(TEX_FRACT_WIDTH),
  .COLOR_WIDTH(COLOR_WIDTH)
)
u_texture_filter(
  .clk(clk),
  .nreset(nreset),
  .clr(filter_clr_c),

  .scale_method(scale_method_r),
  .in_valid(gather_filter_valid),
  .in_ready(gather_filter_ready),
  .texel_quad(gather_filter_texel_quad),
  .coeff_x(gather_filter_coeff_x),
  .coeff_y(tex_y_fract_r),

  .out_valid(filter_out_valid),
  .out_ready(filter_out_ready),
  .out_pixel(filter_out_pixel)
);

// -------------------------------- Pixel interface

wire pixel_data_border_c = !image_hit_x_c || (ipu_fsm_r == IPU_FSM_ACTIVE_EMPTY_LINE);
assign pixel_data = pixel_data_border_c ? border_color_r : filter_out_pixel;
assign pixel_border = pixel_data_border_c;
assign pixel_valid = 
  (ipu_fsm_r == IPU_FSM_ACTIVE || ipu_fsm_r == IPU_FSM_ACTIVE_EMPTY_LINE)
  && (pixel_data_border_c ? 1'b1 : filter_out_valid);

assign filter_out_ready =
  (ipu_fsm_r == IPU_FSM_WAIT_FILL) ? !filter_out_valid :                    // Wait for pipeline to fill
                                     (pixel_ready && !pixel_data_border_c); // Forward 'pixel_ready'

// -------------------------------- FSM

always_comb
  case (ipu_fsm_r)

    // Leave idle state on control interface transfer
    IPU_FSM_IDLE:
      ipu_fsm_nxt_c <= ctl_transfer_c ? IPU_FSM_INIT : IPU_FSM_IDLE;

    // Intermediate state for setting internal registers
    IPU_FSM_INIT:
      ipu_fsm_nxt_c <= IPU_FSM_Y_HIT_MISS;

    // Decision point - does current line contain part of the image?
    IPU_FSM_Y_HIT_MISS:
      ipu_fsm_nxt_c <= image_hit_y_c ? IPU_FSM_START_COMPUTE_TEX_Y : IPU_FSM_START_EMPTY_LINE;

    // Compute y texture coordinate
    // Wait for the address compute block to become ready
    IPU_FSM_START_COMPUTE_TEX_Y:
      ipu_fsm_nxt_c <= addr_compute_in_ready ? IPU_FSM_WAIT_COMPUTE_TEX_Y : IPU_FSM_START_COMPUTE_TEX_Y;

    // Wait for the address compute block to respond
    IPU_FSM_WAIT_COMPUTE_TEX_Y:
      ipu_fsm_nxt_c <= addr_compute_out_valid ? IPU_FSM_WAIT_TEX_REQUEST : IPU_FSM_WAIT_COMPUTE_TEX_Y;

    // Wait for the external logic to acknowledge texture line request
    IPU_FSM_WAIT_TEX_REQUEST:
      ipu_fsm_nxt_c <= tex_request_transfer_c ? IPU_FSM_START : IPU_FSM_WAIT_TEX_REQUEST;

    // Starting processing of an empty line
    IPU_FSM_START_EMPTY_LINE:
      ipu_fsm_nxt_c <= IPU_FSM_ACTIVE_EMPTY_LINE;

    // IPU output active, outputs only border pixels
    IPU_FSM_ACTIVE_EMPTY_LINE:
      ipu_fsm_nxt_c <= last_pixel_transfer_c ? IPU_FSM_DONE : IPU_FSM_ACTIVE_EMPTY_LINE;

    // Starting processing of non-empty line
    // Clears the pipeline
    IPU_FSM_START:
      ipu_fsm_nxt_c <= IPU_FSM_WAIT_FILL;

    // Waits for the pipeline to fill with data
    IPU_FSM_WAIT_FILL:
      ipu_fsm_nxt_c <= filter_out_valid ? IPU_FSM_ACTIVE : IPU_FSM_WAIT_FILL;

    // IPU active, outputs line containing the image
    IPU_FSM_ACTIVE:
      ipu_fsm_nxt_c <= last_pixel_transfer_c ? IPU_FSM_DONE : IPU_FSM_ACTIVE;

    // Line processing done, going idle
    IPU_FSM_DONE:
      ipu_fsm_nxt_c <= IPU_FSM_IDLE;

    default:
      ipu_fsm_nxt_c <= 'x;

  endcase

endmodule
