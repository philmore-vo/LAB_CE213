//==============================================================================
// File         : sram_model.v
// Description  : Mo hinh hanh vi (behavioral model) cua chip SRAM
//                IS61LV25616AL-10 de mo phong trong ModelSim.
//                KHONG phai RTL synthesize duoc — chi de thay the chip
//                SRAM ngoai trong khi kiem tra tb_sram_de2_32x8.
//
//   Dac diem:
//     - 256K x 16-bit (A[17:0], I/O[15:0]).
//     - Dieu khien tich cuc thap: /CE, /OE, /WE, /UB, /LB.
//     - Khi /CE=0 va /WE=0 -> ghi: sample data bus theo /UB, /LB; byte
//       khong duoc cho phep (/UB=1 hoac /LB=1) khong thay doi.
//     - Khi /CE=0 va /WE=1 va /OE=0 -> doc: drive I/O theo byte enable;
//       byte khong duoc cho phep -> Z.
//     - Moi truong hop khac -> bus Z.
//
//   Khong mo phong timing chinh xac cua datasheet (tAA, tSD...); chi
//   combinational/event-driven de kiem tra logic cua module sram_de2_32x8.
//==============================================================================
`timescale 1ns/1ps

module sram_model (
    input  wire [17:0] A,
    inout  wire [15:0] IO,
    input  wire        CE_N,
    input  wire        OE_N,
    input  wire        WE_N,
    input  wire        UB_N,
    input  wire        LB_N
);

    // 256K x 16-bit — qua lon de khoi tao full. Dung "associative-like"
    // thong qua unpacked array; ModelSim cap phat lazy nen khong sao.
    // Neu muon kiem tra full 256K nen giam xuong con 2^8 cho nhanh.
    reg [15:0] mem [0:262143];     // 2^18 = 262144 word

    //--------------------------------------------------------------------------
    // Drive bus khi doc (read cycle)
    //--------------------------------------------------------------------------
    reg [15:0] rdata;
    always @(*) begin
        rdata[15:8] = mem[A][15:8];
        rdata[7:0]  = mem[A][7:0];
    end

    wire read_active = (CE_N == 1'b0) && (WE_N == 1'b1) && (OE_N == 1'b0);

    assign IO[15:8] = (read_active && (UB_N == 1'b0)) ? rdata[15:8] : 8'bz;
    assign IO[7:0]  = (read_active && (LB_N == 1'b0)) ? rdata[7:0]  : 8'bz;

    //--------------------------------------------------------------------------
    // Ghi khi /CE = 0 va /WE = 0; ghi o canh len cua /WE (WE_N 0 -> 1)
    // de dung voi timing cua datasheet (data duoc latch o canh len WE).
    // Tai day de don gian: ghi ngay khi WE_N = 0 va cac byte-enable hop le.
    //--------------------------------------------------------------------------
    always @(negedge WE_N) begin
        if (CE_N == 1'b0) begin
            if (UB_N == 1'b0) mem[A][15:8] <= IO[15:8];
            if (LB_N == 1'b0) mem[A][7:0]  <= IO[7:0];
        end
    end

endmodule
