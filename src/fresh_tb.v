// Testbench for fresh.v

`timescale 1ns/1ps

module fresh_tb #(parameter ADDR_W = 17) ();

    // Main (fast) processing
    reg clk;
    reg [ADDR_W-1:0] check_addr;
    wire out_fresh;

    // FIFO (slower) range inputs
    reg range_clk;
    reg rst;  // Xilinx FIFO requires rst to be on wr_clk domain
    reg wr_en;
    reg [ADDR_W-1:0] input_range_low;
    reg [ADDR_W-1:0] input_range_high;
    reg input_range_fresh;
    wire fifo_full;

    top dut (
        .clk                (clk                ),
        .check_addr         (check_addr         ),
        .out_fresh          (out_fresh          ),
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

        // Load FIFO with a couple of ranges
        @(posedge range_clk);
        input_range_low = 20;
        input_range_high = 24;
        input_range_fresh = 1;
        wr_en = 1;

        @(posedge range_clk);
        input_range_low = 6;
        input_range_high = 8;
        input_range_fresh = 1;

        @(posedge range_clk);
        wr_en = 0;
    end


endmodule