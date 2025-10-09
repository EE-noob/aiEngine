`timescale 1ns / 1ps

module tb_serial_divider;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] dividend;
    reg [15:0] divisor;

    // Outputs
    wire done;
    wire [15:0] quotient;
    wire [15:0] remainder;

    // Instantiate the Unit Under Test (UUT)
    serial_divider uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .done(done),
        .quotient(quotient),
        .remainder(remainder)
    );

    // Clock generator: 10ns period
    always #5 clk = ~clk;

    // Result flag
    integer all_pass;
    integer test_count;

    // Task: run one division and check result
    task run_test(input [15:0] din, input [15:0] dor);
        reg [15:0] exp_quot;
        reg [15:0] exp_rem;
        begin
            // Apply inputs
            dividend = din;
            divisor  = dor;
            start    = 1'b1;
            @(posedge clk);
            start = 1'b0;

            // Wait for done
            wait (done == 1);
            @(posedge clk);

            test_count = test_count + 1;

            // Calculate expected result (software model)
            if (dor != 0) begin
                exp_quot = din / dor;
                exp_rem  = din % dor;
                if (quotient === exp_quot && remainder === exp_rem) begin
                    $display("PASS: %0d / %0d = %0d ... %0d", din, dor, quotient, remainder);
                end else begin
                    $display("FAIL: %0d / %0d => got %0d ... %0d, expected %0d ... %0d",
                        din, dor, quotient, remainder, exp_quot, exp_rem);
                    all_pass = 0; // 标记失败
                end
            end else begin
                $display("SKIP: Divide by zero: %0d / %0d", din, dor);
                test_count = test_count - 1; // 不计入总测试次数
            end
        end
    endtask


    initial begin
        $fsdbDumpfile("sim.fsdb");
        $fsdbDumpvars(0,tb_serial_divider);
        $fsdbDumpMDA(0,tb_serial_divider);
    end

    // Initial block: run multiple randomized tests
    integer i;
    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        dividend = 0;
        divisor = 1;
        all_pass = 1;
        test_count = 0;

        // Reset
        #20;
        rst_n = 1;
        #10;

        // Run 20 random tests
        for (i = 0; i < 200000; i = i + 1) begin
            @(posedge clk);
            run_test($random, $random);
        end

        // Summary result
        if (test_count == 0) begin
            $display("WARNING: No valid test cases executed.");
        end else if (all_pass) begin
            $display("====================================");
            $display("        ✅ ALL TESTS PASSED         ");
            $display("====================================");
        end else begin
            $display("====================================");
            $display("        ❌ TEST FAILED DETECTED     ");
            $display("====================================");
        end

        $finish;
    end

endmodule
