// Makes a 8-bit address, 1-bit data simple dual-port RAM

module sdp_bram #(parameter ADDR_W = 17)
(
    input clk,
    input [ADDR_W-1:0] read_addr,
    input [ADDR_W-1:0] write_addr,
    input write_val,
    input write_en,
    output reg read_val
);

    // Main memory
    // (* ram_style = "block" *)
    reg mem [0:2**ADDR_W-1];
    integer i;

    initial begin
        for (i = 0; i < 2**ADDR_W; i=i+1) begin
            mem[i] = 1'b0;
        end
    end

    always @(posedge clk) begin
        // Write logic
        if (write_en) begin
            mem[write_addr] <= write_val;
        end

        // Read logic
        read_val <= mem[read_addr];
    end

endmodule