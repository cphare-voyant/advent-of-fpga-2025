// Top level module, with correct I/O

module top #(parameter ADDR_W = 17)
(
    input clk,
    input [ADDR_W-1:0] read_addr,
    input [ADDR_W-1:0] write_addr,
    input write_val,
    input write_en,
    output wire read_val
);

    reg [ADDR_W-1:0] read_addr_reg;
    reg [ADDR_W-1:0] write_addr_reg;
    reg write_val_reg;
    reg write_en_reg;

    always @(posedge clk) begin
        // Register all inputs
        read_addr_reg   <=  read_addr;
        write_addr_reg  <=  write_addr;
        write_val_reg   <=  write_val;
        write_en_reg    <=  write_en;
    end

    sdp_bram #(.ADDR_W(ADDR_W)) mem1
    (
        .clk        (clk            ),
        .read_addr  (read_addr_reg  ),
        .write_addr (write_addr_reg ),
        .write_val  (write_val_reg  ),
        .write_en   (write_en_reg   ),
        .read_val   (read_val       )
    );



endmodule