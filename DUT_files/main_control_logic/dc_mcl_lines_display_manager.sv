module dc_mcl_lines_display_manager #(
  parameter SCR_SIZE_WIDTH,
  parameter SCALE_METHOD_WIDTH,
  parameter RGB_WIDTH
)(
  input wire clk,
  input wire nrst,
  input wire en,
  
  //VU interface
  input wire vertical_blanking,
  input wire horizontal_blanking,
  
  //config manager interface
  input wire[(SCR_SIZE_WIDTH-1):0] conf_image_offset_x,
  input wire[(SCR_SIZE_WIDTH-1):0] conf_image_offset_y,
  input wire[(SCR_SIZE_WIDTH-1):0] conf_image_width,
  input wire[(SCR_SIZE_WIDTH-1):0] conf_image_height,
  input wire[(SCR_SIZE_WIDTH-1):0] conf_screen_width,
  input wire[(SCR_SIZE_WIDTH-1):0] conf_screen_height,
  input wire[(SCR_SIZE_WIDTH-1):0] conf_tex_width,
  input wire[(SCR_SIZE_WIDTH-1):0] conf_tex_height,
  input wire[(SCALE_METHOD_WIDTH-1):0] conf_scale_method,
  input wire[(RGB_WIDTH-1):0] conf_border_color,
  output wire underrun,
  output wire frame_finished,
  input wire conf_valid,
  output wire conf_ready,
  
  // IPU interface
  output wire ctl_valid,
  input wire ctl_ready,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_screen_y,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_x,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_y,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_width,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_image_height,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_screen_width,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_tex_width,
  output wire[(SCR_SIZE_WIDTH-1):0] ctl_tex_height,
  output wire[(SCALE_METHOD_WIDTH-1):0] ctl_scale_method,
  output wire[(RGB_WIDTH-1):0] ctl_border_color,
  input wire status_done
);

localparam LINES_DISPLAY_FSM_WIDTH = 3;
localparam LINES_DISPLAY_FSM_POWER_UP = LINES_DISPLAY_FSM_WIDTH'('h0);
localparam LINES_DISPLAY_FSM_IDLE = LINES_DISPLAY_FSM_WIDTH'('h1);
localparam LINES_DISPLAY_FSM_SEND_REQUEST = LINES_DISPLAY_FSM_WIDTH'('h2);
localparam LINES_DISPLAY_FSM_WAIT = LINES_DISPLAY_FSM_WIDTH'('h3);
localparam LINES_DISPLAY_FSM_UNDERRUN = LINES_DISPLAY_FSM_WIDTH'('h4);

wire horizontal_blanking_nxt_c;
wire horizontal_blanking_en_c;
reg horizontal_blanking_r;
assign horizontal_blanking_en_c = en;
assign horizontal_blanking_nxt_c = horizontal_blanking;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    horizontal_blanking_r <= '0;
  end else if(horizontal_blanking_en_c) begin
    horizontal_blanking_r <= horizontal_blanking_nxt_c;
  end
end

reg[(LINES_DISPLAY_FSM_WIDTH-1):0] lines_display_fsm_r;
reg[(LINES_DISPLAY_FSM_WIDTH-1):0] lines_display_fsm_nxt_c;
reg ctl_valid_r;
wire lines_display_fsm_en_c;
wire texture_over;
reg frame_finished_r;
reg frame_finished_nxt_c;
assign lines_display_fsm_en_c = en;

always_comb begin
  case(lines_display_fsm_r)
    LINES_DISPLAY_FSM_IDLE:
      lines_display_fsm_nxt_c = (conf_valid) ? 
                                LINES_DISPLAY_FSM_SEND_REQUEST : 
                                LINES_DISPLAY_FSM_IDLE;
    LINES_DISPLAY_FSM_SEND_REQUEST:
      lines_display_fsm_nxt_c = (frame_finished_r) ? 
                                LINES_DISPLAY_FSM_IDLE : 
                                (!ctl_valid_r) ? 
                                LINES_DISPLAY_FSM_SEND_REQUEST :
                                (ctl_ready) ? 
                                LINES_DISPLAY_FSM_WAIT : 
                                LINES_DISPLAY_FSM_SEND_REQUEST;
    LINES_DISPLAY_FSM_WAIT:
      lines_display_fsm_nxt_c = (status_done && !horizontal_blanking_r) ?
                                LINES_DISPLAY_FSM_SEND_REQUEST : 
                                (status_done && horizontal_blanking_r) ? 
                                LINES_DISPLAY_FSM_UNDERRUN :
                                LINES_DISPLAY_FSM_WAIT;
    LINES_DISPLAY_FSM_UNDERRUN:
      lines_display_fsm_nxt_c = LINES_DISPLAY_FSM_IDLE;
  endcase
end

always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    lines_display_fsm_r <= LINES_DISPLAY_FSM_IDLE;
  end else if(lines_display_fsm_en_c) begin
    lines_display_fsm_r <= lines_display_fsm_nxt_c;
  end
end

reg underrun_r;
reg conf_ready_r;
reg ctl_valid_nxt_c;
reg underrun_nxt_c;
reg conf_ready_nxt_c;
always_comb begin
  case(lines_display_fsm_nxt_c)
    LINES_DISPLAY_FSM_IDLE: begin
      ctl_valid_nxt_c = '0;
      underrun_nxt_c = '0;
      frame_finished_nxt_c = '0;
      conf_ready_nxt_c = 1'h1;
    end
    LINES_DISPLAY_FSM_SEND_REQUEST: begin
      ctl_valid_nxt_c = (lines_display_fsm_r == LINES_DISPLAY_FSM_SEND_REQUEST) || lines_display_fsm_r == LINES_DISPLAY_FSM_IDLE;  // valid delayed by one cycle, bacause data needs to go through config manager
      underrun_nxt_c = '0;
      frame_finished_nxt_c = texture_over && status_done;
      conf_ready_nxt_c = '0;
    end
    LINES_DISPLAY_FSM_WAIT: begin
      ctl_valid_nxt_c = '0;
      underrun_nxt_c = '0;
      frame_finished_nxt_c = '0;
      conf_ready_nxt_c = '0;
    end
    LINES_DISPLAY_FSM_UNDERRUN: begin
      ctl_valid_nxt_c = '0;
      underrun_nxt_c = 1'h1;
      frame_finished_nxt_c = '0;
      conf_ready_nxt_c = '0;
    end
  endcase
end

always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    ctl_valid_r <= '0;
    underrun_r <= '0;
    frame_finished_r <= '0;
    conf_ready_r <= '0;
  end else if(lines_display_fsm_en_c) begin
    ctl_valid_r <= ctl_valid_nxt_c;
    underrun_r <= underrun_nxt_c;
    frame_finished_r <= frame_finished_nxt_c;
    conf_ready_r <= conf_ready_nxt_c;
  end
end
assign conf_ready = conf_ready_r;
assign ctl_valid = ctl_valid_r;
assign underrun = underrun_r;
assign frame_finished = frame_finished_r;

reg[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_x_nxt_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_y_nxt_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_image_width_nxt_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_image_height_nxt_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_screen_width_nxt_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_tex_width_nxt_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_tex_height_nxt_c;
reg[(SCALE_METHOD_WIDTH-1):0] ctl_scale_method_nxt_c;
reg[(RGB_WIDTH-1):0] ctl_border_color_nxt_c;
wire ctl_data_en_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_x_r;
reg[(SCR_SIZE_WIDTH-1):0] ctl_image_offset_y_r;
reg[(SCR_SIZE_WIDTH-1):0] ctl_image_width_r;
reg[(SCR_SIZE_WIDTH-1):0] ctl_image_height_r;
reg[(SCR_SIZE_WIDTH-1):0] ctl_screen_width_r;
reg[(SCR_SIZE_WIDTH-1):0] ctl_tex_width_r;
reg[(SCR_SIZE_WIDTH-1):0] ctl_tex_height_r;
reg[(SCALE_METHOD_WIDTH-1):0] ctl_scale_method_r;
reg[(RGB_WIDTH-1):0] ctl_border_color_r;
assign ctl_data_en_c = en && (status_done || 
                                 lines_display_fsm_r == LINES_DISPLAY_FSM_IDLE);
assign ctl_image_offset_x_nxt_c = conf_image_offset_x;
assign ctl_image_offset_y_nxt_c = conf_image_offset_y;
assign ctl_image_width_nxt_c = conf_image_width;
assign ctl_image_height_nxt_c = conf_image_height;
assign ctl_screen_width_nxt_c = conf_screen_width;
assign ctl_tex_width_nxt_c = conf_tex_width;
assign ctl_tex_height_nxt_c = conf_tex_height;
assign ctl_scale_method_nxt_c = conf_scale_method;
assign ctl_border_color_nxt_c = conf_border_color;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    ctl_image_offset_x_r <= '0;
    ctl_image_offset_y_r <= '0;
    ctl_image_width_r <= '0;
    ctl_image_height_r <= '0;
    ctl_screen_width_r <= '0;
    ctl_tex_width_r <= '0;
    ctl_tex_height_r <= '0;
    ctl_scale_method_r <= '0;
    ctl_border_color_r <= '0;
  end else if(ctl_data_en_c) begin
    ctl_image_offset_x_r <= ctl_image_offset_x_nxt_c;
    ctl_image_offset_y_r <= ctl_image_offset_y_nxt_c;
    ctl_image_width_r <= ctl_image_width_nxt_c;
    ctl_image_height_r <= ctl_image_height_nxt_c;
    ctl_screen_width_r <= ctl_screen_width_nxt_c;
    ctl_tex_width_r <= ctl_tex_width_nxt_c;
    ctl_tex_height_r <= ctl_tex_height_nxt_c;
    ctl_scale_method_r <= ctl_scale_method_nxt_c;
    ctl_border_color_r <= ctl_border_color_nxt_c;
  end
end
assign ctl_image_offset_x = ctl_image_offset_x_r;
assign ctl_image_offset_y = ctl_image_offset_y_r;
assign ctl_image_width = ctl_image_width_r;
assign ctl_image_height = ctl_image_height_r;
assign ctl_screen_width = ctl_screen_width_r;
assign ctl_tex_width = ctl_tex_width_r;
assign ctl_tex_height = ctl_tex_height_r;
assign ctl_scale_method = ctl_scale_method_r;
assign ctl_border_color = ctl_border_color_r;

// line counter
wire ctl_screen_y_en_c;
wire[(SCR_SIZE_WIDTH-1):0] ctl_screen_y_nxt_c;
reg[(SCR_SIZE_WIDTH-1):0] ctl_screen_y_r;
wire[(SCR_SIZE_WIDTH-1):0] screen_y_inc;
assign texture_over = ctl_screen_y_r >= (conf_screen_height-SCR_SIZE_WIDTH'('h1));
assign screen_y_inc = ctl_screen_y_r + SCR_SIZE_WIDTH'('h1);
assign ctl_screen_y_nxt_c = (!texture_over) ? 
                            screen_y_inc : '0;
assign ctl_screen_y_en_c =  en && status_done;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    ctl_screen_y_r <= '0;
  end else if(ctl_screen_y_en_c) begin 
    ctl_screen_y_r <= ctl_screen_y_nxt_c;
  end
end
assign ctl_screen_y = ctl_screen_y_r;

endmodule
