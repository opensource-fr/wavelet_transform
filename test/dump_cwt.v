module dump();
    initial begin
        $dumpfile ("wavelet_transform.vcd");
        $dumpvars (0, wavelet_transform);
        #1;
    end
endmodule

