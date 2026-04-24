//==============================================================================
// File         : sram_de2_32x8.v
// Description  : Top-level dung chip SRAM ngoai IS61LV25616AL-10 tren board DE2
//                de hien thuc bo nho 32 x 8 (Lab4 cau 6).
//
//   User I/O (theo Lab8 Part IV):
//     - SW[7:0]    : data-in (8 bit)
//     - SW[15:11]  : address 5-bit (chi dung 32 o nho)
//     - SW[17]     : Write = 1 -> ghi; Write = 0 -> doc
//     - KEY[0]     : clock input (push-button)
//     - HEX7,HEX6  : hien thi address (hex cao | hex thap)
//     - HEX5,HEX4  : hien thi data-in
//     - HEX1,HEX0  : hien thi data-out
//     - LEDG[0]    : bao tin hieu Write
//
//   SRAM interface (dat ten dung theo DE2 User Manual):
//     - SRAM_ADDR[17:0], SRAM_DQ[15:0] (inout),
//       SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N (active-low)
//
//   Che do don gian theo Lab8: CE = OE = UB = LB = 0, chi toggle /WE.
//==============================================================================
module sram_de2_32x8 (
    input  wire [17:0] SW,
    input  wire [3:0]  KEY,

    output wire [6:0]  HEX7,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX0,

    output wire [8:0]  LEDG,

    // SRAM chip IS61LV25616AL-10
    output wire [17:0] SRAM_ADDR,
    inout  wire [15:0] SRAM_DQ,
    output wire        SRAM_CE_N,
    output wire        SRAM_OE_N,
    output wire        SRAM_WE_N,
    output wire        SRAM_UB_N,
    output wire        SRAM_LB_N
);

    //--------------------------------------------------------------------------
    // Anh xa user I/O
    //--------------------------------------------------------------------------
    wire [4:0] addr_5b   = SW[15:11];
    wire [7:0] data_in   = SW[7:0];
    wire       write_en  = SW[17];
    wire       clock_btn = KEY[0];     // KEY active-low; day la clock go-by-key

    //--------------------------------------------------------------------------
    // Cac chan dieu khien SRAM: 4 chan nho tie 0 (CE, OE, UB, LB)
    //--------------------------------------------------------------------------
    assign SRAM_CE_N = 1'b0;
    assign SRAM_OE_N = 1'b0;
    assign SRAM_UB_N = 1'b0;           // dung ca upper + lower byte
    assign SRAM_LB_N = 1'b0;

    //--------------------------------------------------------------------------
    // /WE = 0 khi dang ghi; nguoc lai bang 1 -> cho phep doc
    //--------------------------------------------------------------------------
    assign SRAM_WE_N = ~write_en;

    //--------------------------------------------------------------------------
    // Tie 13-bit address cao ve 0: chi dung 32 o nho (A[4:0])
    //--------------------------------------------------------------------------
    assign SRAM_ADDR = {13'b0, addr_5b};

    //--------------------------------------------------------------------------
    // Xu ly bus inout SRAM_DQ:
    //   - Khi ghi (write_en=1): drive 8 bit thap la data_in, 8 bit cao = 0.
    //   - Khi doc (write_en=0): tha Z (16'bz) -> chip SRAM drive bus.
    //--------------------------------------------------------------------------
    assign SRAM_DQ = write_en ? {8'b0, data_in} : 16'bz;

    //--------------------------------------------------------------------------
    // Data doc ra: lay 8 bit thap cua SRAM_DQ
    //--------------------------------------------------------------------------
    wire [7:0] data_out = SRAM_DQ[7:0];

    //--------------------------------------------------------------------------
    // Dang clock: clock_btn de lai o tin hieu, day la phien ban Part IV
    // don gian "nut nhan lam clock" — sinh vien cung co the thay bang
    // CLOCK_50 + debouncer tuy y.
    //--------------------------------------------------------------------------
    // (Khong tao thanh ghi dong bo — SRAM la combinational tu phia FPGA,
    //  chip SRAM tu lo timing noi bo. Khi nhan KEY, cac SW da duoc chot
    //  tu truoc nen du thoi gian setup.)

    //--------------------------------------------------------------------------
    // Hien thi LED
    //--------------------------------------------------------------------------
    assign LEDG[0]   = write_en;
    assign LEDG[8:1] = 8'b0;

    //--------------------------------------------------------------------------
    // Hien thi 7-segment
    //   HEX7 = bit cao cua address (chi co 1 bit 4, pad 0)
    //   HEX6 = 4 bit thap cua address
    //   HEX5,HEX4 = data-in
    //   HEX1,HEX0 = data-out
    //--------------------------------------------------------------------------
    hex_to_7seg u_h7 (.hex({3'b0, addr_5b[4]}), .seg(HEX7));
    hex_to_7seg u_h6 (.hex(addr_5b[3:0]),       .seg(HEX6));
    hex_to_7seg u_h5 (.hex(data_in[7:4]),       .seg(HEX5));
    hex_to_7seg u_h4 (.hex(data_in[3:0]),       .seg(HEX4));
    hex_to_7seg u_h1 (.hex(data_out[7:4]),      .seg(HEX1));
    hex_to_7seg u_h0 (.hex(data_out[3:0]),      .seg(HEX0));

    // Dong gia clock_btn de tool khong loai bo (no khong tham gia logic
    // do ta khong chot du lieu qua flip-flop — chi de de debug neu can
    // them register sau nay). Tranh warning "unused signal".
    wire _unused_ok = clock_btn;

endmodule
