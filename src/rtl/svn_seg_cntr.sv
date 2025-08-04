`include "lscc_defines.svh"

import lscc_pkg::*;

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

  localparam u_byte DsplyDepth  = 16;
  localparam u_byte SelDepth    = 4;

  localparam u_int  SysFreq     = CLK_IN_MHZ * 1000 * 1000;
  localparam u_int  PsWidth     = $clog2(SysFreq);
  localparam u_int  DsplyWidth  = $clog2(DsplyDepth);
  localparam u_int  SelWidth    = $clog2(SelDepth);

  // 7 Segment display decoder (DsplyDepth x 8 ROM)
  localparam u_byte Seg7Dsply [DsplyDepth] = {
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

  // 7 Segment Selector - cycle segments in arbitrary pattern
  localparam logic [2:0] Seg7Sel [SelDepth] = {
    3'b100,
    3'b010,
    3'b001,
    3'b010
  };


  // Signal Declarations

  logic [   PsWidth-1:0] prescaler;
  logic                  prescaler_tc;
  logic [DsplyWidth-1:0] seg_cntr;
  logic [  SelWidth-1:0] sel_cntr;

  // Module Behaviour

`ifndef SIM

  // Prescaler generates 1Hz pulse to enable display counter
  always_ff @(posedge clk_i, negedge rstn_i) begin : prescale
    if (!rstn_i) begin
      prescaler    <= 'b0;
      prescaler_tc <= 'b0;
    end else begin
      prescaler    <= prescaler_tc ? 'b0 : prescaler + 'b1;
      prescaler_tc <= (prescaler == PsWidth'(SysFreq - 2));
    end
  end : prescale

`else

  // Disable prescaler for simulation
  assign prescaler = 'b0;
  assign prescaler_tc = 1'b1;

`endif

  // Display Decoder - Increment once per prescaler pulse & decode seg_counter value
  always_ff @(posedge clk_i) begin : dsply_dcdr
    if (prescaler_tc) begin
      seg_cntr      <= (seg_cntr < DsplyDepth-1) ? seg_cntr + 'b1 : 'b0;
      seg_display_o <= LED_POLARITY ? Seg7Dsply[seg_cntr] : ~Seg7Dsply[seg_cntr] ;
    end
  end : dsply_dcdr

  // Cycle 7seg display
  always_ff @(posedge clk_i, negedge rstn_i) begin : dsply_sel
    if (!rstn_i) begin
      sel_cntr  <= 'b0;
      seg_sel_o <= Seg7Sel[0];
    end else if (prescaler_tc) begin
      sel_cntr  <= (sel_cntr < SelDepth-1) ? sel_cntr + 'b1 : 'b0;
      seg_sel_o <= Seg7Sel[sel_cntr];
    end
  end : dsply_sel

endmodule
