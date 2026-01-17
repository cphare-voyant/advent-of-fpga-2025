// Testbench for fresh.v

`timescale 1ns/1ps

module fresh_tb #(parameter ADDR_W = 17) ();

    // Main (fast) processing
    reg clk;
    reg [ADDR_W-1:0] check_addr;
    wire out_fresh;
    wire check_ready;

    // FIFO (slower) range inputs
    reg range_clk;
    reg rst;  // Xilinx FIFO requires rst to be on wr_clk domain
    reg wr_en;
    reg [ADDR_W-1:0] input_range_low;
    reg [ADDR_W-1:0] input_range_high;
    reg input_range_fresh;
    wire fifo_full;

    // Tracking signal
    integer fresh_count = 0;

    top dut (
        .clk                (clk                ),
        .check_addr         (check_addr         ),
        .out_fresh          (out_fresh          ),
        .check_ready        (check_ready        ),
        .range_clk          (range_clk          ),
        .rst                (rst                ),
        .wr_en              (wr_en              ),
        .input_range_low    (input_range_low    ),
        .input_range_high   (input_range_high   ),
        .input_range_fresh  (input_range_fresh  ),
        .fifo_ready         (fifo_ready         )
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        range_clk = 0;
        forever #7 range_clk = ~range_clk;
    end

    initial begin
        rst = 1;
        wr_en = 0;

        #100
        rst = 0;
        #500  // FIFO takes ~450 ns to leave reset

        // Load FIFO with example ranges
        @(posedge range_clk);
        input_range_low = 3;
        input_range_high = 5;
        input_range_fresh = 1;
        wr_en = 1;

        @(posedge range_clk);
        input_range_low = 10;
        input_range_high = 14;

        @(posedge range_clk);
        input_range_low = 16;
        input_range_high = 20;

        @(posedge range_clk);
        input_range_low = 12;
        input_range_high = 18;

        @(posedge range_clk);
        wr_en = 0;


        // Test fast readout
        @(posedge check_ready);  // Wait for RAM to fully update
        @(posedge clk);
        check_addr = 1;
        
        @(posedge clk);
        check_addr = 5;
        if (out_fresh) fresh_count = fresh_count + 1;
        
        @(posedge clk);
        check_addr = 8;
        if (out_fresh) fresh_count = fresh_count + 1;
        
        @(posedge clk);
        check_addr = 11;
        if (out_fresh) fresh_count = fresh_count + 1;

        @(posedge clk);
        check_addr = 17;
        if (out_fresh) fresh_count = fresh_count + 1;

        @(posedge clk);
        check_addr = 32;
        if (out_fresh) fresh_count = fresh_count + 1;

        @(posedge clk);
        if (out_fresh) fresh_count = fresh_count + 1;

        $display(fresh_count);  // Should be 3
    end


endmodule