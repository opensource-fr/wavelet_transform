`default_nettype none
`define ELEM_RATIO (0.577472)

module wavelet_transform #(
    parameter BITS_PER_ELEM = 8
) (
    // Clock
    input wire i_clk,

    // Input Wire
    input wire [BITS_PER_ELEM - 1:0] i_value,

    // Output leds
    output wire o_LED2
);

`ifdef VERILATOR
  parameter COUNTER_WIDTH = 4;
`else
  parameter COUNTER_WIDTH = 25;
`endif

  // highest frequency sets the sample rate
  parameter BASE_FREQ = 1;
  parameter BASE_NUM_ELEM = 3;
  parameter NUM_FILTERS = 8;
  /* parameter BITS_PER_ELEM = 8; */
  // number of elements is ∝ HIGHEST_FREQ/THIS_FREQ
  // really we should calculate the ratio of the elements to produce the freq
  // NUM_ELEM * ELEM_RATIO
  parameter TOTAL_TAPS = (1 + $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, NUM_FILTERS - 1)));
  parameter BITS_PER_TAP = BITS_PER_ELEM;

  parameter TOTAL_BITS = BITS_PER_TAP * TOTAL_TAPS;

  // verilator lint_off UNUSED
  wire [TOTAL_BITS - 1:0] taps;
  // verilator lint_on UNUSED

  /* wire [BITS_PER_ELEM - 1:0] i_value = {BITS_PER_ELEM{1'b1}}; */
  /* assign i_value = {BITS_PER_ELEM{1'b1}}; */

  shift_register_line #(
      .COUNTER_WIDTH(COUNTER_WIDTH),
      .TOTAL_TAPS(TOTAL_TAPS),
      .BITS_PER_TAP(BITS_PER_ELEM),
      .TOTAL_BITS(TOTAL_BITS)
  ) srl_1 (
      .i_clk  (i_clk),
      .i_value(i_value),
      .o_LED  (o_LED2),
      .o_taps (taps[TOTAL_BITS-1:0])
  );

  genvar i;

  generate
    for (i = 0; i < NUM_FILTERS; i = i + 1) begin
      if ($rtoi(BASE_NUM_ELEM * 1 / $pow(`ELEM_RATIO, i)) % 2 == 1) begin
        fir #(
            .BITS_PER_ELEM(BITS_PER_ELEM),
            .NUM_ELEM($rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, i))),
            .CENTER_FREQ(BASE_FREQ * $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, i)))
        ) fir_1 (
            .i_clk(i_clk),
            //verilator lint_off WIDTH
            .taps (taps[BITS_PER_ELEM*$rtoi(BASE_NUM_ELEM*1.0/$pow(`ELEM_RATIO, i))-1:0])
            //verilator lint_on WIDTH
        );
      end else begin
        fir #(
            .BITS_PER_ELEM(BITS_PER_ELEM),
            .NUM_ELEM(1 + $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, i))),
            .CENTER_FREQ(BASE_FREQ * $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, i)))
        ) fir_1 (
            .i_clk(i_clk),
            //verilator lint_off WIDTH
            .taps (taps[BITS_PER_ELEM*(1+$rtoi(BASE_NUM_ELEM*1.0/$pow(`ELEM_RATIO, i)))-1:0])
            //verilator lint_on WIDTH
        );
      end
    end
  endgenerate

  // TODO: add formal section
endmodule
