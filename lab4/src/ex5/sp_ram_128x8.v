//==============================================================================
// File         : sp_ram_128x8.v
// Description  : Single-port RAM 128 x 8, dong bo read/write (Lab4 cau 5).
//                - clock : kich canh len
//                - cs    : chip-select, tich cuc cao
//                - wr_e  : 1 -> ghi, 0 -> doc
//                - oe    : output enable; khi oe=1 va cs=1 va wr_e=0 -> DUT
//                          drive data bus; nguoc lai tha tri-state (Z)
//                - addr  : dia chi 7-bit
//                - data  : bus 8-bit, kieu inout
//==============================================================================
module sp_ram_128x8 (
    input  wire       clock,
    input  wire       cs,
    input  wire       wr_e,
    input  wire       oe,
    input  wire [6:0] addr,
    inout  wire [7:0] data
);

    reg [7:0] mem [0:127];
    reg [7:0] rdata;

    // Ghi dong bo
    always @(posedge clock) begin
        if (cs && wr_e)
            mem[addr] <= data;
    end

    // Doc dong bo vao thanh ghi rdata
    always @(posedge clock) begin
        if (cs && !wr_e)
            rdata <= mem[addr];
    end

    // Drive data bus khi dang doc va oe=1
    assign data = (cs && !wr_e && oe) ? rdata : 8'bz;

endmodule
