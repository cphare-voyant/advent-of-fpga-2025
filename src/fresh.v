// Fresh Ingredient Identifier

module top #(parameter ADDR_W = 17)
(
    // Main (fast) processing
    input clk,
    input [ADDR_W-1:0] check_addr,
    output reg out_fresh,

    // FIFO (slower) range inputs
    input range_clk,
    input rst,  // Xilinx FIFO requires rst to be on wr_clk domain
    input wr_en,
    input [ADDR_W-1:0] input_range_low,
    input [ADDR_W-1:0] input_range_high,
    input input_range_fresh,
    output fifo_ready
);

    // FIFO read-side signals
    wire [ADDR_W-1:0] range_begin, range_end;
    wire range_fresh;
    wire fifo_empty; // TODO: What do we use fifo_empty for?
    wire rd_en;  // TODO: What do we use rd_en for?
    wire fifo_data_NC;  // Extra don't care bit to absorb FIFO data width

    // FIFO write-side ready logic
    wire wr_rst_busy;
    wire fifo_full;
    assign fifo_ready = !fifo_full && !wr_rst_busy;

    // RAM load signals
    reg [ADDR_W-1:0] current_addr;

    // Main memory load logic
    // If FIFO is not empty, assert read and dequeue a range from the FIFO
    // Loop through range, writing bits to RAM until current_addr == end of range
    always @(posedge clk)
    begin
        // TODO: Work in progress here
    end






    // Fresh range FIFO
    // 36 bits wide (17-bit (ADDR_W) start + 17-bit stop + 1-bit fresh/spoiled_n + 1-bit don't care) x 1023
    xpm_fifo_async #(
        .FIFO_MEMORY_TYPE     ("block"),
        .FIFO_READ_LATENCY    (1      ),        // DECIMAL, consider 0 for FWFT
        .FIFO_WRITE_DEPTH     (1024   ),
        .READ_DATA_WIDTH      (36     ),
        .READ_MODE            ("std"  ),
        .SIM_ASSERT_CHK       (1      ),
        .WRITE_DATA_WIDTH     (36     ),
        .WR_DATA_COUNT_WIDTH  (11     )         // For debug    
    )
    range_fifo (
        // Write side
        .rst            (rst        ),
        .wr_clk         (range_clk  ),
        .wr_en          (wr_en      ),
        .full           (fifo_full  ),
        .wr_rst_busy    (wr_rst_busy),
        .din            ({input_range_low, input_range_high, input_range_fresh, 1'b0}),

        // Read side
        .rd_clk (clk        ),
        .rd_en  (rd_en      ),
        .empty  (fifo_empty ),
        .dout   ({range_begin, range_end, range_fresh, fifo_data_NC})
    );

    // Fresh ingredient BRAM
    sdp_bram #(.ADDR_W(ADDR_W)) fresh_ram
    (
        .clk        (clk            ),
        .read_addr  (read_addr_reg  ),
        .write_addr (write_addr_reg ),
        .write_val  (write_val_reg  ),
        .write_en   (write_en_reg   ),
        .read_val   (read_val       )
    );



endmodule