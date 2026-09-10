`timescale 1ns/1ps

module tb_prefetcher_3d_3x3x3;

    logic        clk;
    logic        reset;
    logic [31:0] address_i;
    logic [31:0] address_o;
    logic        valid;
    logic        ready;

    prefetcher_3d_3x3x3 dut (
        .clk       (clk),
        .reset     (reset),
        .address_i (address_i),
        .address_o (address_o),
        .valid     (valid),
        .ready     (ready)
    );

    always #5 clk <= ~clk;

    always @(posedge clk) begin
        if (ready)
            $display("time=%0t input=%0d output=%0d", $time, address_i, address_o);
    end

    initial begin

        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_prefetcher_3d_3x3x3);

        clk       = 0;
        reset     = 1;
        address_i = 0;
        valid     = 0;

        // Reset
        #20;
        reset = 0;

        // Test 1: corner 0
        // Expected: 1, 3, 9
        @(negedge clk);
        address_i = 0;
        valid = 1;

        @(negedge clk);
        valid = 0;

        repeat (8) @(negedge clk);

        // Test 2: center 13
        // Expected: 12, 14, 10, 16, 4, 22
        address_i = 13;
        valid = 1;

        @(negedge clk);
        valid = 0;

        repeat (8) @(negedge clk);

        // Test 3: corner 26
        // Expected: 25, 23, 17
        address_i = 26;
        valid = 1;

        @(negedge clk);
        valid = 0;

        repeat (8) @(negedge clk);

        // Test 4: face point 10
        // Expected: 9, 11, 13, 1, 19
        address_i = 10;
        valid = 1;

        @(negedge clk);
        valid = 0;

        repeat (8) @(negedge clk);

        // Test 5: edge point 9
        // Expected: 10, 12, 0, 18
        address_i = 9;
        valid = 1;

        @(negedge clk);
        valid = 0;

        repeat (8) @(negedge clk);


        $finish;
    end

endmodule
