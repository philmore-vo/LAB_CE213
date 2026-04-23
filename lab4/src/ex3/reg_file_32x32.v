//==============================================================================
// File         : reg_file_32x32.v
// Description  : Tap thanh ghi (register file) 32 x 32-bit theo Lab4 cau 3.
//                - 2 port doc bat dong bo (combinational read)
//                - 1 port ghi dong bo (sync write, kich canh len clk)
//                - Khong co thanh ghi R0 dac biet; tat ca 32 thanh ghi deu
//                  co the ghi/doc tu do.
//==============================================================================
module reg_file_32x32 (
    input  wire        clk,
    input  wire        WriteEn,
    input  wire [4:0]  ReadAddress1,
    input  wire [4:0]  ReadAddress2,
    input  wire [4:0]  WriteAddress,
    input  wire [31:0] WriteData,
    output wire [31:0] ReadData1,
    output wire [31:0] ReadData2
);

    reg [31:0] regs [0:31];

    always @(posedge clk) begin
        if (WriteEn)
            regs[WriteAddress] <= WriteData;
    end

    assign ReadData1 = regs[ReadAddress1];
    assign ReadData2 = regs[ReadAddress2];

endmodule
