`default_nettype none

module shift_register_line #(
    parameter COUNTER_WIDTH = 25,
    parameter TOTAL_TAPS = 9,
    parameter BITS_PER_TAP = 8,
    parameter TOTAL_BITS = 9 * 8
) (
    // Clock
    input wire clk,

    // Inputs Streaming
    input wire signed [BITS_PER_TAP - 1:0] i_value,

    // LED
    output wire o_LED,

    // TAPS
    output reg [TOTAL_BITS - 1:0] o_taps
);

  reg stb;
  reg [COUNTER_WIDTH-1:0] counter;

  initial begin
    o_taps = 0;
    stb = 0;
    counter = 0;
  end

  always @(posedge clk) begin
    counter <= counter + 1;
    stb <= 1'b0;
    if (counter == {COUNTER_WIDTH{1'b0}}) begin
      stb <= 1'b1;
    end
  end

  always @(posedge clk) begin
    o_taps <= o_taps;
    /* if (stb == 1'b1) begin */
      // shift in BITS_PER_TAP, one element at a time
      o_taps <= {o_taps[((TOTAL_BITS-1)-BITS_PER_TAP):0], i_value};
      /* stb <= 1'b0; */
    /* end */
  end

  /* assign o_LED = !counter[COUNTER_WIDTH-1]; */

endmodule
