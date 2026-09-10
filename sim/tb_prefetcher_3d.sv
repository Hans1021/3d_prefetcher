`timescale 1ns/1ps

module tb_prefetcher_3d;

    logic clk;
    logic reset;

    // 3x3x3 DUT

    logic [31:0] address_i;
    logic [31:0] address_o;
    logic        valid;
    logic        ready;

    prefetcher_3d dut (
        .clk       (clk),
        .reset     (reset),
        .address_i (address_i),
        .address_o (address_o),
        .valid     (valid),
        .ready     (ready)
    );

    // 4x3x2 DUT

    logic [31:0] address_i_4x3x2;
    logic [31:0] address_o_4x3x2;
    logic        valid_4x3x2;
    logic        ready_4x3x2;

    prefetcher_3d #(
        .X_SIZE(4),
        .Y_SIZE(3),
        .Z_SIZE(2)
    ) dut_4x3x2 (
        .clk       (clk),
        .reset     (reset),
        .address_i (address_i_4x3x2),
        .address_o (address_o_4x3x2),
        .valid     (valid_4x3x2),
        .ready     (ready_4x3x2)
    );

    // 1x3x3 DUT

    logic [31:0] address_i_1x3x3;
    logic [31:0] address_o_1x3x3;
    logic        valid_1x3x3;
    logic        ready_1x3x3;

    prefetcher_3d #(
        .X_SIZE(1),
        .Y_SIZE(3),
        .Z_SIZE(3)
    ) dut_1x3x3 (
        .clk       (clk),
        .reset     (reset),
        .address_i (address_i_1x3x3),
        .address_o (address_o_1x3x3),
        .valid     (valid_1x3x3),
        .ready     (ready_1x3x3)
    );

    always #5 clk <= ~clk;

    // Display outputs
    always @(posedge clk) begin
        if (ready)
            $display("3x3x3: time=%0t input=%0d output=%0d",
                     $time, address_i, address_o);

        if (ready_4x3x2)
            $display("4x3x2: time=%0t input=%0d output=%0d",
                     $time, address_i_4x3x2, address_o_4x3x2);

        if (ready_1x3x3)
            $display("1x3x3: time=%0t input=%0d output=%0d",
                     $time, address_i_1x3x3, address_o_1x3x3);
    end

    initial begin

        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_prefetcher_3d);

        clk   = 0;
        reset = 1;

        address_i = 0;
        valid     = 0;

        address_i_4x3x2 = 0;
        valid_4x3x2     = 0;

        address_i_1x3x3 = 0;
        valid_1x3x3     = 0;


        // Reset
        #20;
        reset = 0;


        // ============
        // 3x3x3 TESTS
        // ============

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


        // =======================
        // 4x3x2 TESTS
        //
        // x offset = 1
        // y offset = 4
        // z offset = 12
        // valid addresses = 0-23
        // =======================

        // Test 6: corner 0
        // Expected: 1, 4, 12
        address_i_4x3x2 = 0;
        valid_4x3x2 = 1;

        @(negedge clk);
        valid_4x3x2 = 0;

        repeat (8) @(negedge clk);


        // Test 7: address 17 = (1,1,1)
        // Expected: 16, 18, 13, 21, 5
        address_i_4x3x2 = 17;
        valid_4x3x2 = 1;

        @(negedge clk);
        valid_4x3x2 = 0;

        repeat (8) @(negedge clk);


        // Test 8: invalid address
        // 4*3*2 = 24 elements, so address 24 is out of range
        // Expected: no output
        address_i_4x3x2 = 24;
        valid_4x3x2 = 1;

        @(negedge clk);
        valid_4x3x2 = 0;

        repeat (8) @(negedge clk);


        // ============================================================
        // 1x3x3 TEST
        //
        // No x neighbors
        // y offset = 1
        // z offset = 3
        // ============================================================

        // Test 9: address 4 = (0,1,1)
        // Expected: 3, 5, 1, 7
        address_i_1x3x3 = 4;
        valid_1x3x3 = 1;

        @(negedge clk);
        valid_1x3x3 = 0;

        repeat (8) @(negedge clk);


        $finish;
    end

endmodule
