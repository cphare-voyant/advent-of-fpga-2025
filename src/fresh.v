// Fresh Ingredient Identifier

module top #(parameter ADDR_W = 17)
(
    // Main (fast) processing
    input clk,
    input [ADDR_W-1:0] check_addr,
    output reg out_fresh,
    output check_ready,

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
    // reg rd_en;  // TODO: What do we use rd_en for?
    reg rd_ready = 1;
    wire fifo_data_NC;  // Extra don't care bit to absorb FIFO data width
    reg [1:0] state = 0;  // 0 if idle, 1 if idle and FIFO has data, 2 if processing
    reg [ADDR_W-1:0] range_current;  // Current range of processing loop
    wire [ADDR_W-1:0] ram_write_addr;
    wire ram_write_val;
    reg ram_write_en = 0;
    wire ram_out;
    assign check_ready = fifo_empty & !writing & !data_valid;  // RAM is correct if no ranges in fifo, no samples being written, or fresh from fifo

    // FIFO write-side ready logic
    wire wr_rst_busy;
    wire fifo_full;
    assign fifo_ready = !fifo_full && !wr_rst_busy;


    // RAM load signals
    // reg [ADDR_W-1:0] current_addr;

    // Main memory load logic
    // If FIFO is not empty, assert read and dequeue a range from the FIFO
    // Loop through range, writing bits to RAM until current_addr == end of range
    // always @(posedge clk)
    // begin
    //     if (state == 1) begin
    //         // Change state
    //         state <= 2;
    //         // Write beginning of range to RAM
    //         ram_write_addr <= range_begin;
    //         ram_write_val <= range_fresh;  // TODO: Can replace with assignment?
    //         ram_write_en <= 1;  // TODO: Can replace with assignment?
    //         // Increment counter
    //         range_current <= range_begin + 1;
    //     end else if (state == 2) begin
    //         if (range_current < range_end) begin
    //             ram_write_addr <= range_current;
    //             range_current <= range_current + 1;
    //         end else begin
    //             state <= 0;
    //             ram_write_en <= 0;
    //             rd_en <= 1;
    //         end
    //     end else if (state == 0) begin
    //         if (!fifo_empty) begin
    //             state <= 1;
    //             rd_en <= 0;
    //         end
    //     end
    //     // Overall logic:
    //     // If FIFO is empty and loop logic is ready, on the next clock cycle, read from the FIFO and begin processing
    //     // If loop logic is pro
    // end


    // // Dummy logic to understand FIFO reads better
    // reg data_valid;
    // assign ram_write_en = data_valid;
    // assign ram_write_val = input_range_fresh;
    // assign ram_write_addr = range_begin;  // Needs changed.
    // always @(posedge clk) begin
    //     rd_en <= !fifo_empty && rd_ready;
    //     if (rd_en) begin
    //         // If read is requested and fifo has data, start a read
    //         data_valid <= 1;
    //     end
    //     if (data_valid) begin
    //         // One clock cycle later, data is good.  Write to RAM.
    //         ram_write_addr <= range_begin;
    //         // TODO: Better, RAM write enable should be just tied to data_valid (at least in this "write only the start" scheme)
    //     end


    reg writing = 0;  // Basic FSM: 0: IDLE, 1: WRITING
    reg [ADDR_W-1:0] current_addr;
    reg [ADDR_W-1:0] end_addr;
    reg data_valid;
    wire rd_en = rd_ready & !fifo_empty;

    assign ram_write_addr = current_addr;
    assign ram_write_val = range_fresh;

    always @(posedge clk) begin
        out_fresh <= ram_out;

        data_valid <= rd_en;

        if (!writing) begin
            // IDLE
            if (rd_en) begin
                rd_ready <= 0;
            end else begin
                rd_ready <= 1;
            end

            if (data_valid) begin
                if (range_begin <= range_end) begin
                    // Save address range
                    current_addr <= range_begin;
                    end_addr <= range_end;
                    writing <= 1;
                    rd_ready <= 0;

                    // First write
                    ram_write_en <= 1;
                end
            end
        end else begin
            // WRITING
            if (current_addr == end_addr) begin
                writing <= 0;
                ram_write_en <= 0;
                rd_ready <= 1;
            end else begin
                current_addr <= current_addr + 1;
                // ram_write_en remains 1
            end
        end
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
        .read_addr  (check_addr     ),
        .write_addr (ram_write_addr ),
        .write_val  (ram_write_val  ),
        .write_en   (ram_write_en   ),
        .read_val   (ram_out        )
    );



endmodule