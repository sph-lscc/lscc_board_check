//
// LED flash sequence modelled on KITT car
//
// One full forward + reverse sweep per 2 seconds
//
`include "../../lib/svh/lscc_defines.svh"

module led_kitt #(
    int CLK_IN_MHZ   = 125,
    bit LED_POLARITY = 1'b0,
    int NUMLEDS      = 8    //Minimum = 3, else pattern indiscernable
) (
    input                       clk_i,
    input                       rstn_i,
    output logic [NUMLEDS-1:0]  led_display_o
);

  localparam int SeqLength = 2 * (NUMLEDS - 1);
  localparam int SysFreq   = CLK_IN_MHZ * 1000 * 1000 / SeqLength;
  localparam int PsWidth   = $clog2(SysFreq);

  // Signal Declarations

  logic [PsWidth-1:0] prescaler;
  logic               prescaler_tc /* synthesis syn_keep=1 */; 
  logic [NUMLEDS-1:0] seq_up;
  logic [NUMLEDS-1:0] seq_dn;

  // Module Behaviour

`ifndef SIM

  // Prescaler generates 1Hz pulse to enable display counter
  always_ff @(posedge clk_i, negedge rstn_i) begin : prescale
    if (!rstn_i) prescaler <= 'b0;
    else prescaler <= prescaler_tc ? 'b0 : prescaler + 1'b1;
  end : prescale

  assign prescaler_tc = (prescaler == SysFreq - 1);

`else

  // Disable prescaler for simulation
  assign prescaler    =  'b0;
  assign prescaler_tc = 1'b1;

`endif

  // Display Sequencer - Increment sequence once per prescaler pulse;
  always_ff @(posedge clk_i, negedge rstn_i) begin : dsply_seq
    if (!rstn_i) begin

      seq_up <= 'b1;
      seq_dn <= 'b0;

      for (int i=0; i < NUMLEDS; i++)
        led_display_o[i] <= LED_POLARITY;

    end
    else if (prescaler_tc) begin

      seq_up <= {1'b0,              seq_up[NUMLEDS-3:0], seq_dn[1]};
      seq_dn <= {seq_up[NUMLEDS-2], seq_dn[NUMLEDS-1:2], 1'b0};

      for (int i=0; i < NUMLEDS; i++)
        led_display_o[i] <= LED_POLARITY ~^ (seq_up[i] | seq_dn[i]);

    end
  end : dsply_seq

  // Decode output
  //always_comb begin : dsply_dcd
  //  for (int i=0; i < NUMLEDS; i++)
  //    led_display_o[i] = LED_POLARITY ~^ (seq_up[i] | seq_dn[i]);
  //end : dsply_dcd

endmodule
