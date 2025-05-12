//
// LED flash sequence modelled on KITT car
//
// One full forward + reverse sweep per second
//
`include "../../lib/svh/lscc_defines.svh"

module led_kitt #(
    int CLK_IN_MHZ   = 125,
    bit LED_POLARITY = 1'b0
) (
    input              clk_i,
    input              rstn_i,
    output logic [7:0] led_display_o
);

  // Local Parameters

  localparam bit [13:0][7:0] LEDDecoder = {
    8'b00000010,
    8'b00000100,
    8'b00001000,
    8'b00010000,
    8'b00100000,
    8'b01000000,
    8'b10000000,
    8'b01000000,
    8'b00100000,
    8'b00010000,
    8'b00001000,
    8'b00000100,
    8'b00000010,
    8'b00000001
  };

  localparam int SysFreq = CLK_IN_MHZ * 1000 * 1000 / 14;
  localparam int PsWidth = $clog2(SysFreq);

  // Signal Declarations

  logic [        3:0] led_counter;
  logic [PsWidth-1:0] prescaler;
  logic               prescaler_tc;

  // Module Behaviour

`ifndef SIM

  // Prescaler generates 1Hz pulse to enable display counter
  always_ff @(posedge clk_i, negedge rstn_i) begin : prescale
    if (!rstn_i) prescaler <= 'b0;
    else prescaler <= prescaler_tc ? PsWidth'(0) : prescaler + PsWidth'(1);
  end : prescale

  assign prescaler_tc = (prescaler == SysFreq - 1);

`else

  // Disable prescaler for simulation
  assign prescaler    =  'b0;
  assign prescaler_tc = 1'b1;

`endif

  // Display Decoder - Increment once per prescaler pulse to value 13; decode value
  always_ff @(posedge clk_i, negedge rstn_i) begin : dsply_dcdr
    if (!rstn_i) begin
      led_counter   <= 'b0;
      led_display_o <= 'b0;
    end
    else if (prescaler_tc) begin
      led_counter   <= led_counter > 4'hC ? 4'h0 : led_counter + 4'h1;
      led_display_o <= LED_POLARITY ? LEDDecoder[led_counter] : ~LEDDecoder[led_counter];
    end
  end : dsply_dcdr

endmodule
