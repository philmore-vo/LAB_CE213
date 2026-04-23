//==============================================================================
// File         : tb_sram_de2_32x8.v
// Description  : Testbench self-checking cho top-level sram_de2_32x8.
//                Noi top-level voi mo hinh behavioral sram_model (thay
//                chip SRAM ngoai). Driver mo phong nguoi dung set SW,
//                nhan KEY va kiem tra HEX0..HEX1 so voi gia tri da ghi.
//
//                Kich ban kiem tra:
//                  - Ghi 32 cap (addr, data) khac nhau qua SW + KEY
//                  - Chuyen sang mode read, quet lai 32 dia chi, kiem
//                    tra data_out (HEX1:HEX0 decoded) khop gia tri ghi
//==============================================================================
`timescale 1ns/1ps

module tb_sram_de2_32x8;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam TIMEOUT_NS = 100_000;
    localparam LOG_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex6/tb_sram_de2_32x8.log";
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex6/tb_sram_de2_32x8.vcd";

    //--------------------------------------------------------------------------
    // DE2 I/O mo phong
    //--------------------------------------------------------------------------
    reg  [17:0] SW;
    reg  [3:0]  KEY;
    wire [6:0]  HEX7, HEX6, HEX5, HEX4, HEX1, HEX0;
    wire [8:0]  LEDG;

    //--------------------------------------------------------------------------
    // SRAM interconnect
    //--------------------------------------------------------------------------
    wire [17:0] SRAM_ADDR;
    wire [15:0] SRAM_DQ;
    wire        SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N;

    //--------------------------------------------------------------------------
    // Bookkeeping
    //--------------------------------------------------------------------------
    integer log_fd;
    integer test_id;
    integer pass_cnt;
    integer fail_cnt;

    //--------------------------------------------------------------------------
    // DUT = top-level
    //--------------------------------------------------------------------------
    sram_de2_32x8 dut (
        .SW        (SW),
        .KEY       (KEY),
        .HEX7      (HEX7),
        .HEX6      (HEX6),
        .HEX5      (HEX5),
        .HEX4      (HEX4),
        .HEX1      (HEX1),
        .HEX0      (HEX0),
        .LEDG      (LEDG),
        .SRAM_ADDR (SRAM_ADDR),
        .SRAM_DQ   (SRAM_DQ),
        .SRAM_CE_N (SRAM_CE_N),
        .SRAM_OE_N (SRAM_OE_N),
        .SRAM_WE_N (SRAM_WE_N),
        .SRAM_UB_N (SRAM_UB_N),
        .SRAM_LB_N (SRAM_LB_N)
    );

    //--------------------------------------------------------------------------
    // SRAM chip (mo hinh hanh vi) - thay the IS61LV25616AL tren board
    //--------------------------------------------------------------------------
    sram_model u_sram (
        .A    (SRAM_ADDR),
        .IO   (SRAM_DQ),
        .CE_N (SRAM_CE_N),
        .OE_N (SRAM_OE_N),
        .WE_N (SRAM_WE_N),
        .UB_N (SRAM_UB_N),
        .LB_N (SRAM_LB_N)
    );

    //==========================================================================
    // Logging
    //==========================================================================
    task tb_log;
        input [8*128-1:0] msg;
        begin
            $display("[%0t ns] %0s", $time, msg);
            if (log_fd) $fdisplay(log_fd, "[%0t ns] %0s", $time, msg);
        end
    endtask

    task tb_section;
        input [8*128-1:0] title;
        begin
            tb_log("--------------------------------------------------");
            tb_log(title);
            tb_log("--------------------------------------------------");
        end
    endtask

    //==========================================================================
    // Giai ma 7-segment active-low -> 4-bit hex (bang tra cuu nghich)
    //==========================================================================
    function [3:0] seg_to_hex;
        input [6:0] s;
        begin
            case (s)
                7'b100_0000 : seg_to_hex = 4'h0;
                7'b111_1001 : seg_to_hex = 4'h1;
                7'b010_0100 : seg_to_hex = 4'h2;
                7'b011_0000 : seg_to_hex = 4'h3;
                7'b001_1001 : seg_to_hex = 4'h4;
                7'b001_0010 : seg_to_hex = 4'h5;
                7'b000_0010 : seg_to_hex = 4'h6;
                7'b111_1000 : seg_to_hex = 4'h7;
                7'b000_0000 : seg_to_hex = 4'h8;
                7'b001_0000 : seg_to_hex = 4'h9;
                7'b000_1000 : seg_to_hex = 4'hA;
                7'b000_0011 : seg_to_hex = 4'hB;
                7'b100_0110 : seg_to_hex = 4'hC;
                7'b010_0001 : seg_to_hex = 4'hD;
                7'b000_0110 : seg_to_hex = 4'hE;
                7'b000_1110 : seg_to_hex = 4'hF;
                default     : seg_to_hex = 4'hX;
            endcase
        end
    endfunction

    //==========================================================================
    // Thao tac nguoi dung
    //==========================================================================
    task do_write;
        input [4:0] addr;
        input [7:0] data;
        begin
            // Dat Write=1, addr, data-in
            SW[17]    = 1'b1;
            SW[15:11] = addr;
            SW[7:0]   = data;
            #5;
            // Nhan KEY[0] de mo phong canh len: 1->0->1
            KEY[0] = 1'b0;
            #10;
            KEY[0] = 1'b1;
            #10;
            // Nha Write ve 0 de ket thuc chu ky ghi (WE_N 0->1 trigger
            // latch trong sram_model)
            SW[17] = 1'b0;
            #5;
        end
    endtask

    task do_read_check;
        input [4:0] addr;
        input [7:0] expected;
        reg   [7:0] got;
        begin
            SW[17]    = 1'b0;
            SW[15:11] = addr;
            #10;            // cho bus on dinh
            got = {seg_to_hex(HEX1), seg_to_hex(HEX0)};
            test_id = test_id + 1;
            if (got === expected) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  addr=%0d  HEX1HEX0=%h exp=%h",
                         $time, test_id, addr, got, expected);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  addr=%0d  HEX1HEX0=%h exp=%h",
                        $time, test_id, addr, got, expected);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  addr=%0d  HEX1HEX0=%h exp=%h",
                         $time, test_id, addr, got, expected);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  addr=%0d  HEX1HEX0=%h exp=%h",
                        $time, test_id, addr, got, expected);
            end
        end
    endtask

    //==========================================================================
    // Test cases
    //==========================================================================
    task tc_write_read_32;
        integer i;
        reg [7:0] pattern;
        begin
            tb_section("TC1 : ghi 32 o nho, doc lai qua HEX1:HEX0");
            // Ghi 32 cap (addr, addr ^ 8'hA5)
            for (i = 0; i < 32; i = i + 1) begin
                pattern = i[7:0] ^ 8'hA5;
                do_write(i[4:0], pattern);
            end
            // Doc lai va kiem tra
            for (i = 0; i < 32; i = i + 1) begin
                pattern = i[7:0] ^ 8'hA5;
                do_read_check(i[4:0], pattern);
            end
        end
    endtask

    task tc_boundary;
        begin
            tb_section("TC2 : ghi/doc bien addr=0 va addr=31");
            do_write(5'd0,  8'hDE);
            do_write(5'd31, 8'hAD);
            do_read_check(5'd0,  8'hDE);
            do_read_check(5'd31, 8'hAD);
        end
    endtask

    //==========================================================================
    // Main
    //==========================================================================
    initial begin
        log_fd   = $fopen(LOG_PATH, "w");
        test_id  = 0;
        pass_cnt = 0;
        fail_cnt = 0;
        SW  = 18'b0;
        KEY = 4'b1111;

        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_sram_de2_32x8);

        if (log_fd == 0)
            $display("WARN: cannot open log file, tiep tuc khong ghi log file");

        tb_log("==================================================");
        tb_log("  sram_de2_32x8 : tb start (SRAM chip ngoai)");
        tb_log("==================================================");
        tb_log("INFO: LEDG[0] = Write signal; seg decoder dung bang tra cuu.");

        tc_write_read_32();
        tc_boundary();

        tb_log("==================================================");
        $display("[%0t ns] SUMMARY  total=%0d  pass=%0d  fail=%0d",
                 $time, pass_cnt + fail_cnt, pass_cnt, fail_cnt);
        if (log_fd)
            $fdisplay(log_fd,
                "[%0t ns] SUMMARY  total=%0d  pass=%0d  fail=%0d",
                $time, pass_cnt + fail_cnt, pass_cnt, fail_cnt);

        if (fail_cnt == 0) tb_log("RESULT : ALL TESTS PASSED");
        else               tb_log("RESULT : TEST FAILURES DETECTED");

        if (log_fd) $fclose(log_fd);
        $finish;
    end

    //--------------------------------------------------------------------------
    // Watchdog
    //--------------------------------------------------------------------------
    initial begin
        #TIMEOUT_NS;
        $display("[%0t ns] FATAL: simulation timeout (%0d ns)", $time, TIMEOUT_NS);
        if (log_fd) begin
            $fdisplay(log_fd, "[%0t ns] FATAL: simulation timeout (%0d ns)",
                      $time, TIMEOUT_NS);
            $fclose(log_fd);
        end
        $finish;
    end

endmodule
