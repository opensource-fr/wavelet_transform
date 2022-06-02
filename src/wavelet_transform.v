`default_nettype none
`define ELEM_RATIO (0.577472)
`timescale 1ns/1ns

module wavelet_transform #(
    parameter BITS_PER_ELEM = 8,
    parameter TOTAL_FILTERS = 8,
    parameter SUM_TRUNCATION = 8
) (
    // Clock
    input wire clk,

    // Reset
    input wire rst,

    // Input Wire
    input wire signed [BITS_PER_ELEM - 1:0] i_value,

    // data_input clock (rising edge)
    input wire i_data_clk,

    // multiplexing for output channels
    input wire [7:0] i_select_output_channel,

    // 8 bit output, channel selected by multiplexer
    output wire [SUM_TRUNCATION - 1:0] o_multiplexed_wavelet_out,

    // set the multiplexed wavelet out pins as outputs
    output [7:0] io_oeb

);
// From Python Ricker-Wavelet Generator:
// taps approx_bits_needed filter_values
// 3 15 c77fc7
// 5 15 e4dd7fdde4 // NOTE: using 5 instead of 6 for waveform capture
// 8 15 fde9c71212c7e9fd // NOTE: 8 replaced w/9 taps (better waveform capture)
// 9 16 73'hFEEAC8127F12C8EAFE
// 15 17 fef7e7cfc9f9507f50f9c9cfe7f7fe
// 26 17 00fefcf8f0e4d5c9c9dd073e6c6c3e07ddc9c9d5e4f0f8fcfe00
// 46 18 000000fefdfbf8f3ede6ded5cdc8c7cddaef0b2b4b667878664b2b0befdacdc7c8cdd5dee6edf3f8fbfdfe000000
// 80 19 0000000000fefefdfcfbf9f7f5f2efebe7e2ddd8d3cecac8c7c8cbd1dae5f30315283b4d5d6b767c7c766b5d4d3b281503f3e5dad1cbc8c7c8caced3d8dde2e7ebeff2f5f7f9fbfcfdfefe0000000000
// 140 20 000000000000000000fefefefdfdfcfcfbfaf9f8f7f6f4f3f1efedeae8e5e2dfdddad7d4d1cecccac8c7c7c7c8c9cccfd3d9dfe6edf60009141e29343f4a535d656d73787c7e7e7c78736d655d534a3f34291e140900f6ede6dfd9d3cfccc9c8c7c7c7c8caccced1d4d7dadddfe2e5e8eaedeff1f3f4f6f7f8f9fafbfcfcfdfdfefefe000000000000000000
 /* 3 15 c77fc7 */
/* 6 14 fbd5efefd5fb */
/* 9 16 f9dfc81f7f1fc8dff9 */
/* 16 16 00fcf3e1cbcd01555501cdcbe1f3fc00 */
/* 27 17 00fefbf6ede0d2c8cbe10c416d7f6d410ce1cbc8d2e0edf6fbfe00 */
/* 47 18 0000fefdfcfaf6f2ebe4dcd3ccc7c8cfddf30e2e4d67787f78674d2e0ef3ddcfc8c7ccd3dce4ebf2f6fafcfdfe0000 */
/* 81 19 00000000fefefdfdfcfaf9f7f4f1eeeae5e0dbd6d2cdcac7c7c8ccd2dbe7f505172a3c4e5e6c767c7f7c766c5e4e3c2a1705f5e7dbd2ccc8c7c7cacdd2d6dbe0e5eaeef1f4f7f9fafcfdfdfefe00000000 */
/* 141 20 0000000000000000fefefefefdfdfcfcfbfaf9f8f7f5f4f2f0eeeceae7e4e2dfdcd9d6d3d0cecccac8c7c7c7c8caccd0d4d9e0e7eef7000a151f2a35404a545d666d73787c7e7f7e7c78736d665d544a40352a1f150a00f7eee7e0d9d4d0cccac8c7c7c7c8caccced0d3d6d9dcdfe2e4e7eaeceef0f2f4f5f7f8f9fafbfcfcfdfdfefefefe0000000000000000 */



  // output bits
  wire [(TOTAL_FILTERS*SUM_TRUNCATION - 1):0] truncated_wavelet_out;

  // set the multiplexed wavelet out pins as outputs
  assign io_oeb = 8'h00;

  wire start_calc;

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
  // number of elements is ∝ HIGHEST_FREQ/THIS_FREQ
  // really we should calculate the ratio of the elements to produce the freq
  // NUM_ELEM * ELEM_RATIO
  /* parameter TOTAL_TAPS = (1 + $rtoi(BASE_NUM_ELEM * 1.0 / $pow(`ELEM_RATIO, NUM_FILTERS - 1))); */
  parameter TOTAL_TAPS = 1120; // for 8 filters starting at 3 elements
  parameter BITS_PER_TAP = BITS_PER_ELEM;

  parameter TOTAL_BITS = BITS_PER_TAP * TOTAL_TAPS;

  wire [TOTAL_BITS - 1:0] taps;

  output_multiplexer #(
      .NUM_FILTERS(NUM_FILTERS),
      .SUM_TRUNCATION(SUM_TRUNCATION)
  ) om_1 (
      .clk(clk),
      .rst(rst),
      .i_truncated_wavelet_out(truncated_wavelet_out),
      .i_select_output_channel(i_select_output_channel),
      .o_multiplexed_wavelet_out(o_multiplexed_wavelet_out)
  );

  shift_register_line #(
      .TOTAL_TAPS(TOTAL_TAPS),
      .BITS_PER_TAP(BITS_PER_ELEM),
      .TOTAL_BITS(TOTAL_BITS)
  ) srl_1 (
      .clk  (clk),
      .rst(rst),
      .i_value(i_value),
      .i_data_clk (i_data_clk),
      .o_start_calc (start_calc),
      .o_taps (taps[TOTAL_BITS-1:0])
    );

    // taps is the number of bits in the filter
    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(3),
      .FILTER_VAL(24'hC77FC7),
      .MAX_BITS(16)
    ) fir_0 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*3) - 1:0]),
      .o_wavelet(truncated_wavelet_out[7:0]),
      .i_start_calc(start_calc)
    );

    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(5),
      .FILTER_VAL(40'hE4DD7FDDE4),
      .MAX_BITS(16)
    ) fir_1 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*5) - 1:0]),
      .o_wavelet(truncated_wavelet_out[15:8]),
      .i_start_calc(start_calc)
    );

    /* f9dfc81f7f1fc8dff9 */
    // NOTE: using 9 instead of 8 elem, as the 9-taps capture the waveform better than 8
    /* .FILTER_VAL(72'hFEEAC8127F12C8EAFE), */
    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(9),
      .FILTER_VAL(72'hF9DFC81F7F1FC8DFF9),
      .MAX_BITS(16)
    ) fir_2 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*9) - 1:0]),
      .o_wavelet(truncated_wavelet_out[23:16]),
      .i_start_calc(start_calc)
    );

    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(15),
      .FILTER_VAL(120'hFEF7E7CFC9F9507F50F9C9CFE7F7FE),
      .MAX_BITS(17)
    ) fir_3 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*15) - 1:0]),
      .o_wavelet(truncated_wavelet_out[31:24]),
      .i_start_calc(start_calc)
    );

    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(26),
      .FILTER_VAL(208'h00FEFCF8F0E4D5C9C9DD073E6C6C3E07DDC9C9D5E4F0F8FCFE00),
      .MAX_BITS(18)
    ) fir_4 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*26) - 1:0]),
      .o_wavelet(truncated_wavelet_out[39:32]),
      .i_start_calc(start_calc)
    );

    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(46),
      .FILTER_VAL(368'h000000FEFDFBF8F3EDE6DED5CDC8C7CDDAEF0B2B4B667878664B2B0BEFDACDC7C8CDD5DEE6EDF3F8FBFDFE000000),
      .MAX_BITS(19)
    ) fir_5 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*46) - 1:0]),
      .o_wavelet(truncated_wavelet_out[47:40]),
      .i_start_calc(start_calc)
    );

    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(80),
      .FILTER_VAL(640'h0000000000FEFEFDFCFBF9F7F5F2EFEBE7E2DDD8D3CECAC8C7C8CBD1DAE5F30315283B4D5D6B767C7C766B5D4D3B281503F3E5DAD1CBC8C7C8CACED3D8DDE2E7EBEFF2F5F7F9FBFCFDFEFE0000000000),
      .MAX_BITS(19)
    ) fir_6 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*80) - 1:0]),
      .o_wavelet(truncated_wavelet_out[55:48]),
      .i_start_calc(start_calc)
    );


    fir #(
      .BITS_PER_ELEM(BITS_PER_ELEM),
      .SUM_TRUNCATION(SUM_TRUNCATION),
      .NUM_ELEM(140),
      .FILTER_VAL(1120'h000000000000000000FEFEFEFDFDFCFCFBFAF9F8F7F6F4F3F1EFEDEAE8E5E2DFDDDAD7D4D1CECCCAC8C7C7C7C8C9CCCFD3D9DFE6EDF60009141E29343F4A535D656D73787C7E7E7C78736D655D534A3F34291E140900F6EDE6DFD9D3CFCCC9C8C7C7C7C8CACCCED1D4D7DADDDFE2E5E8EAEDEFF1F3F4F6F7F8F9FAFBFCFCFDFDFEFEFE000000000000000000),
      .MAX_BITS(20)
    ) fir_7 (
      .clk(clk),
      .rst(rst),
      .taps (taps[(BITS_PER_ELEM*140) - 1:0]),
      .o_wavelet(truncated_wavelet_out[63:56]),
      .i_start_calc(start_calc)
    );

  // TODO: add formal section
endmodule
