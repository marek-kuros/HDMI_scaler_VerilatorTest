module dc_mcl_config_manager #(
  parameter SCR_SIZE_WIDTH,
  parameter AXI_ARADDR_WIDTH,
  parameter RGB_WIDTH,
  parameter SCALE_METHOD_WIDTH
)(
  input wire clk,
  input wire nrst,
  input wire en,

  input wire sw_test_en,
  input wire[2:0] sw_layer_0_pos,
  input wire[2:0] sw_layer_0_scaling,
  input wire[1:0] sw_scaling_method,  // sw inputs are connected to switches on board
  input wire[(SCR_SIZE_WIDTH-1):0] const_input_size_width,
  input wire[(SCR_SIZE_WIDTH-1):0] const_input_size_height,  // input image dims
  input wire[(SCR_SIZE_WIDTH-1):0] const_output_size_width,
  input wire[(SCR_SIZE_WIDTH-1):0] const_output_size_height,  // display dims
  input wire[(AXI_ARADDR_WIDTH-1):0] const_initial_address,
  input wire[(RGB_WIDTH-1):0] const_border_color,
  output wire led_frame_underrun,
  output wire led_frame_finished,
  input wire user_int_valid,
  output wire user_int_ready,

  output wire[(SCR_SIZE_WIDTH-1):0] conf_image_offset_x,
  output wire[(SCR_SIZE_WIDTH-1):0] conf_image_offset_y,
  output wire[(SCR_SIZE_WIDTH-1):0] conf_image_width,
  output wire[(SCR_SIZE_WIDTH-1):0] conf_image_height,  // scaled image dims
  output wire[(SCR_SIZE_WIDTH-1):0] conf_screen_width,
  output wire[(SCR_SIZE_WIDTH-1):0] conf_screen_height,
  output wire[(SCR_SIZE_WIDTH-1):0] conf_tex_width,
  output wire[(SCR_SIZE_WIDTH-1):0] conf_tex_height,  // input image dims
  output wire[(SCALE_METHOD_WIDTH-1):0] conf_scale_method,
  output wire[(RGB_WIDTH-1):0] conf_border_color,
  output wire[(AXI_ARADDR_WIDTH-1):0] conf_tex_address,
  input wire underrun,
  input wire frame_finished,
  output wire conf_valid,
  input wire conf_ready
);

wire[(SCR_SIZE_WIDTH-1):0] cyclic_width;
wire[(SCR_SIZE_WIDTH-1):0] cyclic_height;
wire cyclic_en_c; 
assign cyclic_en_c = sw_layer_0_scaling == 3'b100 || 
                     sw_layer_0_scaling == 3'b101 ||
                     sw_layer_0_scaling == 3'b110;
dc_mcl_trm_cyclic_manager #(
  .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .WIDTH_MANAGER(1)
) width_manager(
  .clk(clk),
  .en(en),
  .nrst(nrst),

  .conf_ready(conf_ready),
  .user_int_valid(user_int_valid),
  .sw_layer_0_scaling(sw_layer_0_scaling),

  .max_dim(const_output_size_width),
  .min_dim(const_input_size_width),
  .curr_dim(cyclic_width)
);

dc_mcl_trm_cyclic_manager #(
  .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
  .WIDTH_MANAGER(0)  
) height_manager(
  .clk(clk),
  .en(en),
  .nrst(nrst),

  .conf_ready(conf_ready),
  .user_int_valid(user_int_valid),
  .sw_layer_0_scaling(sw_layer_0_scaling),

  .max_dim(const_output_size_height),
  .min_dim(const_input_size_height),
  .curr_dim(cyclic_height)
);

  localparam USER_INT_HANDSHAKE_FSM_WIDTH = 2;
  localparam USER_INT_HANDSHAKE_FSM_IDLE = USER_INT_HANDSHAKE_FSM_WIDTH'('h0);
  localparam USER_INT_HANDSHAKE_FSM_SEND_DATA = USER_INT_HANDSHAKE_FSM_WIDTH'('h1);
  localparam USER_INT_HANDSHAKE_FSM_WAIT = USER_INT_HANDSHAKE_FSM_WIDTH'('h2);
  
  reg[(USER_INT_HANDSHAKE_FSM_WIDTH-1):0] user_int_handshake_fsm_r;
  reg[(USER_INT_HANDSHAKE_FSM_WIDTH-1):0] user_int_handshake_fsm_nxt_c;
  wire user_int_handshake_fsm_en_c;
  assign user_int_handshake_fsm_en_c = en;
  
  always_comb begin
    case(user_int_handshake_fsm_r)
      USER_INT_HANDSHAKE_FSM_IDLE:
        user_int_handshake_fsm_nxt_c = (user_int_valid) ?  
                                    USER_INT_HANDSHAKE_FSM_SEND_DATA : 
                                    USER_INT_HANDSHAKE_FSM_IDLE;
      USER_INT_HANDSHAKE_FSM_SEND_DATA:
        user_int_handshake_fsm_nxt_c = (conf_ready) ? 
                                    USER_INT_HANDSHAKE_FSM_WAIT : 
                                    USER_INT_HANDSHAKE_FSM_SEND_DATA;
      USER_INT_HANDSHAKE_FSM_WAIT:
        user_int_handshake_fsm_nxt_c = (conf_ready) ? 
                                    USER_INT_HANDSHAKE_FSM_IDLE : 
                                    USER_INT_HANDSHAKE_FSM_WAIT;
    endcase
  end
  
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      user_int_handshake_fsm_r <= USER_INT_HANDSHAKE_FSM_IDLE;
    end else if(user_int_handshake_fsm_en_c) begin
      user_int_handshake_fsm_r <= user_int_handshake_fsm_nxt_c;
    end
  end
  
  reg user_int_ready_r;
  reg conf_valid_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_screen_width_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_screen_height_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_tex_width_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_tex_height_r;
  reg[(SCALE_METHOD_WIDTH-1):0] conf_scale_method_r;
  reg[(RGB_WIDTH-1):0] conf_border_color_r;
  reg[(AXI_ARADDR_WIDTH-1):0] conf_tex_address_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_width_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_height_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_offset_x_r;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_offset_y_r;

  reg user_int_ready_nxt_c;
  reg conf_valid_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_screen_width_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_screen_height_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_tex_width_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_tex_height_nxt_c;
  reg[(SCALE_METHOD_WIDTH-1):0] conf_scale_method_nxt_c;
  reg[(RGB_WIDTH-1):0] conf_border_color_nxt_c;
  reg[(AXI_ARADDR_WIDTH-1):0] conf_tex_address_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_width_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_height_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_offset_x_nxt_c;
  reg[(SCR_SIZE_WIDTH-1):0] conf_image_offset_y_nxt_c;
  always_comb begin
    case(user_int_handshake_fsm_nxt_c)
      USER_INT_HANDSHAKE_FSM_IDLE: begin
        user_int_ready_nxt_c <= 1'h1;
        conf_valid_nxt_c <= '0;
        conf_screen_width_nxt_c = conf_screen_width_r;
        conf_screen_height_nxt_c = conf_screen_height_r;
        conf_tex_width_nxt_c = conf_tex_width_r;
        conf_tex_height_nxt_c = conf_tex_height_r;
        conf_scale_method_nxt_c = conf_scale_method_r;
        conf_border_color_nxt_c = conf_border_color_r;
        conf_tex_address_nxt_c = conf_tex_address_r;
        conf_image_width_nxt_c = conf_image_width_r;
        conf_image_height_nxt_c = conf_image_height_r;
        conf_image_offset_x_nxt_c = conf_image_offset_x_r;
        conf_image_offset_y_nxt_c = conf_image_offset_y_r;
      end
      USER_INT_HANDSHAKE_FSM_SEND_DATA: begin
        user_int_ready_nxt_c <= '0;
        conf_valid_nxt_c <= 1'h1;
        conf_screen_width_nxt_c = const_output_size_width;
        conf_screen_height_nxt_c = const_output_size_height;
        conf_tex_width_nxt_c = const_input_size_width;
        conf_tex_height_nxt_c = const_input_size_height;
        conf_scale_method_nxt_c = sw_scaling_method;
        conf_border_color_nxt_c = const_border_color;
        conf_tex_address_nxt_c = const_initial_address;
        conf_image_width_nxt_c = (sw_layer_0_scaling == 3'b000) ? 
                                  const_input_size_width :  // no scaling
                                 (sw_layer_0_scaling == 3'b001) ?
                                  const_output_size_width :  // full screen
                                 (sw_layer_0_scaling == 3'b010) ?
                                 (const_input_size_width << 2) :  // 4x upsampling
                                 (sw_layer_0_scaling == 3'b011) ?
                                 (const_input_size_width << 1) :  // 2x upsampling
                                 (cyclic_en_c) ?  // incrementing once per frame
                                  cyclic_width : 
                                  const_input_size_width >> 1;  // 2x downsamping
        conf_image_height_nxt_c = (sw_layer_0_scaling == 3'b000) ? 
                                 const_input_size_height :  // no scaling
                                 (sw_layer_0_scaling == 3'b001) ?
                                 const_output_size_height :  // full screen
                                 (sw_layer_0_scaling == 3'b010) ?
                                 (const_input_size_height << 2) :  // 4x upsampling
                                 (sw_layer_0_scaling == 3'b011) ?
                                 (const_input_size_height << 1) :  // 2x upsampling
                                 (sw_layer_0_scaling == 3'b100) ?
                                 const_input_size_height :
                                 (cyclic_en_c) ?
                                 cyclic_height :  
                                 const_input_size_height >> 1;  // 2x downsamping
        conf_image_offset_x_nxt_c = (sw_layer_0_pos == 3'b000 || sw_layer_0_pos == 3'b010 || 
                                    sw_layer_0_scaling == 3'b001) ? // for fullscreen there must be no offset
                                    '0 :  // left
                                    (sw_layer_0_pos == 3'b001 || sw_layer_0_pos == 3'b011) ? 
                                    (const_output_size_width - conf_image_width_nxt_c) : // right
                                    (sw_layer_0_pos == 3'b100) ? 
                                    ((const_output_size_width >> 1) - (conf_image_width_nxt_c >> 1)) :  // central
                                    (const_output_size_width + conf_image_width_nxt_c);  // non visible
        conf_image_offset_y_nxt_c = (sw_layer_0_pos == 3'b000 || sw_layer_0_pos == 3'b001 || 
                                    sw_layer_0_scaling == 3'b001) ? // for fullscreen there must be no offset
                                    '0 :  // top
                                    (sw_layer_0_pos == 3'b010 || sw_layer_0_pos == 3'b011) ? 
                                    (const_output_size_height - conf_image_height_nxt_c) : // bottom
                                    (sw_layer_0_pos == 3'b100) ? 
                                    ((const_output_size_height >> 1) - (conf_image_height_nxt_c >> 1)) :  // central
                                    (const_output_size_height + conf_image_height_nxt_c);  // non visible
      end
      USER_INT_HANDSHAKE_FSM_WAIT: begin
        user_int_ready_nxt_c <= '0;
        conf_valid_nxt_c <= '0;
        conf_screen_width_nxt_c = conf_screen_width_r;
        conf_screen_height_nxt_c = conf_screen_height_r;
        conf_tex_width_nxt_c = conf_tex_width_r;
        conf_tex_height_nxt_c = conf_tex_height_r;
        conf_scale_method_nxt_c = conf_scale_method_r;
        conf_border_color_nxt_c = conf_border_color_r;
        conf_tex_address_nxt_c = conf_tex_address_r;
        conf_image_width_nxt_c = conf_image_width_r;
        conf_image_height_nxt_c = conf_image_height_r;
        conf_image_offset_x_nxt_c = conf_image_offset_x_r;
        conf_image_offset_y_nxt_c = conf_image_offset_y_r;
      end  
    endcase
  end
  
  always_ff @(posedge clk, negedge nrst) begin
    if(!nrst) begin
      user_int_ready_r <= '0;
      conf_valid_r <= '0;
      conf_screen_width_r <= '0;
      conf_screen_height_r <= '0;
      conf_tex_width_r <= '0;
      conf_tex_height_r <= '0;
      conf_scale_method_r <= '0;
      conf_border_color_r <= '0;
      conf_tex_address_r <= '0;
      conf_image_width_r <= '0;
      conf_image_height_r <= '0;
      conf_image_offset_x_r <= '0;
      conf_image_offset_y_r <= '0;
    end else if(user_int_handshake_fsm_en_c) begin
      user_int_ready_r <= user_int_ready_nxt_c;
      conf_valid_r <= conf_valid_nxt_c;
      conf_screen_width_r <= conf_screen_width_nxt_c;
      conf_screen_height_r <= conf_screen_height_nxt_c;
      conf_tex_width_r <= conf_tex_width_nxt_c;
      conf_tex_height_r <= conf_tex_height_nxt_c;
      conf_scale_method_r <= conf_scale_method_nxt_c;
      conf_border_color_r <= conf_border_color_nxt_c;
      conf_tex_address_r <= conf_tex_address_nxt_c;
      conf_image_width_r <= conf_image_width_nxt_c;
      conf_image_height_r <= conf_image_height_nxt_c;
      conf_image_offset_x_r <= conf_image_offset_x_nxt_c;
      conf_image_offset_y_r <= conf_image_offset_y_nxt_c;
    end
  end
  
  assign conf_valid = conf_valid_r;
  assign user_int_ready = user_int_ready_r;
  assign conf_screen_width = conf_screen_width_r;
  assign conf_screen_height = conf_screen_height_r;
  assign conf_tex_width = conf_tex_width_r;
  assign conf_tex_height  = conf_tex_height_r;
  assign conf_scale_method = conf_scale_method_r;
  assign conf_border_color = conf_border_color_r;
  assign conf_tex_address = conf_tex_address_r;
  assign led_frame_underrun = underrun;
  assign led_frame_finished  = frame_finished;
  assign conf_image_offset_x = conf_image_offset_x_r;
  assign conf_image_offset_y = conf_image_offset_y_r;
  assign conf_image_width = conf_image_width_r;
  assign conf_image_height = conf_image_height_r;
endmodule