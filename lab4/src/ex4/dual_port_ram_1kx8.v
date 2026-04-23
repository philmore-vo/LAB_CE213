//==============================================================================
// File         : dual_port_ram_1kx8.v
// Description  : Dual-port RAM 1024 x 8 (Lab4 cau 4).
//                Dac ta chi co 1 Address, 1 WriteData, 1 ReadData, WriteEn,
//                ReadEn -> hien thuc 1 cong dia chi voi duong ghi/doc
//                tach biet (1R1W tren cung 1 dia chi, sync write, gated
//                read - khop voi kieu M4K block tren Cyclone II).
//==============================================================================
module dual_port_ram_1kx8 (
    input  wire       clk,
    input  wire       WriteEn,
    input  wire       ReadEn,
    input  wire [9:0] Address,
    input  wire [7:0] WriteData,
    output reg  [7:0] ReadData
);

    reg [7:0] mem [0:1023];

    always @(posedge clk) begin
        if (WriteEn) mem[Address] <= WriteData;
        if (ReadEn)  ReadData     <= mem[Address];
    end

endmodule
