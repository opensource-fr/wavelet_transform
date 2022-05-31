`default_nettype none
`define ELEM_RATIO (0.577472)
`timescale 1ns/1ns

module wavelet_transform #(
    parameter BITS_PER_ELEM = 8,
    parameter TOTAL_FILTERS = 4,
    parameter SUM_TRUNCATION = 8
) (
    // Clock
    input wire clk,

    // Input Wire
    input wire signed [BITS_PER_ELEM - 1:0] i_value,

    // data_input clock (rising edge)
    input wire i_data_clk,

    // output bits, (for now all 32 bit signed registers)
    output wire [(TOTAL_FILTERS*SUM_TRUNCATION - 1):0] o_truncated_wavelet_out

);

  wire start_calc;

  parameter COUNTER_WIDTH = 4;

  `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wavelet_transform.vcd");
      $dumpvars (0, wavelet_transform);
    end
  `endif

  // highest frequency sets the sample rate
  parameter BASE_FREQ = 1;
  parameter BASE_NUM_ELEM = 3;
  parameter NUM_FILTERS = TOTAL_FILTERS;
  /* parameter BITS_PER_ELEM = 8; */
  // number of elements is ∝ HIGHEST_FREQ/THIS_FREQ
  // really we should calculate the ratio of the elements to produce the freq
  // NUM_ELEM * ELEM_RATIO
  parameter TOTAL_TAPS = (1 + $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, NUM_FILTERS - 1)));
  parameter BITS_PER_TAP = BITS_PER_ELEM;

  parameter TOTAL_BITS = BITS_PER_TAP * TOTAL_TAPS;

  wire [TOTAL_BITS - 1:0] taps;

  shift_register_line #(
      .TOTAL_TAPS(TOTAL_TAPS),
      .BITS_PER_TAP(BITS_PER_ELEM),
      .TOTAL_BITS(TOTAL_BITS)
  ) srl_1 (
      .clk  (clk),
      .i_value(i_value),
      .o_taps (taps[TOTAL_BITS-1:0]),
      .i_data_clk (i_data_clk),
      .o_start_calc (start_calc)
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
            .clk(clk),
            .taps (taps[BITS_PER_ELEM*$rtoi(BASE_NUM_ELEM*1.0/$pow(`ELEM_RATIO, i))-1:0]),
            .o_wavelet(o_truncated_wavelet_out[SUM_TRUNCATION*i+:SUM_TRUNCATION]),
            .i_start_calc(start_calc)
        );
      end else begin
        fir #(
            .BITS_PER_ELEM(BITS_PER_ELEM),
            .NUM_ELEM(1 + $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, i))),
            .CENTER_FREQ(BASE_FREQ * $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, i)))
        ) fir_1 (
            .clk(clk),
            .taps (taps[BITS_PER_ELEM*(1+$rtoi(BASE_NUM_ELEM*1.0/$pow(`ELEM_RATIO, i)))-1:0]),
            .o_wavelet(o_truncated_wavelet_out[SUM_TRUNCATION*i+:SUM_TRUNCATION]),
            .i_start_calc(start_calc)
        );
      end
    end
  endgenerate

  // TODO: add formal section
endmodule
