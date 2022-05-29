import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import wave
import struct
import random
import math


@cocotb.test()
async def test(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    # open audio files for read and write
    # audio_in = wave.open("./test/middle_c.wav")
    audio_in = wave.open("./test/hello.wav")
    audio_out = wave.open("./test/out.wav", "wb")
    audio_out.setnchannels(audio_in.getnchannels())
    audio_out.setsampwidth(audio_in.getnchannels())
    audio_out.setframerate(audio_in.getframerate())

    nframes = audio_in.getnframes()
    print("sending %d frames" % nframes)

    dut.i_data_clk.value = 0
    counter = 0

    # process audio through dut
    for i in range(nframes):
        await RisingEdge(dut.clk)
        frame = audio_in.readframes(1)
        # print(frame)
        (val,) = struct.unpack("h", frame)

        dut.i_value.value = int(math.sin(0.1*counter*(1 + 0.01*counter))  * 127)
        counter = 1 +counter
        # print(dut.i_value.value)
        # if val > 0:
        #     dut.i_value.value = min(int((val / 32768.0 * 127)), 127)
        # elif val < 0:
        #     dut.i_value.value = max(int((val / 32768.0 * 127)), -127)
        # else:
        #     dut.i_value.value = 0

        # clk in data
        dut.i_data_clk.value = 1

        # print(val, dut.i_value.value)
        # print(dut.i_value)
        await RisingEdge(dut.clk)

        dut.i_data_clk.value = 0

        s = int(str(dut.o_sum[1]), 2)

        if s > 2147483647:
            s = s - 4294967295 - 1

        # input = 0
        # if int(dut.i_value) > 127:
        #     input = int(str(dut.i_value), 2) - 255 - 1
        # else:
        #     input = int(str(dut.i_value), 2)


#         print(val, input, s)
        print(val, dut.i_value, s)

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        # assert(True)
        # raw_out, = struct.pack('i', dut.o_sum[0].value.signed_integer)
        # audio_out.writeframes(raw_out)
