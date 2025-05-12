`include "lscc_defines.svh"

module svn_seg_cntr #(
    byte CLK_IN_MHZ   = 125,
    bit  LED_POLARITY = 1'b0
) (
    input              clk_i,
    input              rstn_i,
    output logic [7:0] seg_display_o,
    output logic [2:0] seg_sel_o
);

  // Local parameters & Constants

  // 7 Segment display decoder (16x8 ROM)
  localparam bit [7:0] Seg7Disp [16] = {
    8'b10111111, //0.
    8'b00000110, //1
    8'b01011011, //2
    8'b01001111, //3
    8'b01100110, //4
    8'b01101101, //5
    8'b01111101, //6
    8'b00000111, //7
    8'b01111111, //8
    8'b01101111, //9
    8'b01110111, //A
    8'b01111100, //B
    8'b00111001, //C
    8'b01011110, //D    
    8'b01111001, //E
    8'b01110001  //F
 };

  localparam int SysFreq = CLK_IN_MHZ * 1000 * 1000;
  localparam int PsWidth = $clog2(SysFreq);

  // Signal Declarations

  logic [PsWidth-1:0] prescaler;
  logic               prescaler_tc;
  logic [        3:0] seg_counter;

  // Module Behaviour

`ifndef SIM

  // Prescaler generates 1Hz pulse to enable display counter
  always_ff @(posedge clk_i, negedge rstn_i) begin : prescale
    if (!rstn_i) prescaler <= 'b0;
    else prescaler <= prescaler_tc ? 'd0 : prescaler + 'd1;
  end : prescale

  assign prescaler_tc = (prescaler == SysFreq - 1);

`else

  // Disable prescaler for simulation
  assign prescaler = 'b0;
  assign prescaler_tc = 1'b1;

`endif

  // Display Decoder - Increment once per prescaler pulse & decode seg_counter value
  always_ff @(posedge clk_i) begin : dsply_dcdr
    if (prescaler_tc) begin
      seg_counter   <= seg_counter + 4'h1;
      seg_display_o <= LED_POLARITY ? Seg7Disp[seg_counter] : ~Seg7Disp[seg_counter];
    end
  end : dsply_dcdr

  // Enable ALL digits of 3 x 7seg display
  assign seg_sel_o = 3'b111;

endmodule
