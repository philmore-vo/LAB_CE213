//==============================================================================
// File         : tb_reg_file_32x32.v
// Description  : Self-checking testbench cho reg_file_32x32 (Lab4 cau 3).
//                Duy tri golden memory, kiem tra:
//                  - Ghi tuan tu 32 thanh ghi, doc lai qua ca 2 port
//                  - Read-during-write (ghi va doc cung dia chi)
//                  - WriteEn=0: ghi khong co tac dung
//                  - Doc 2 dia chi khac nhau cung luc -> 2 port doc lap
//                  - Ngau nhien 50 lan ghi so voi golden
//==============================================================================
`timescale 1ns/1ps

module tb_reg_file_32x32;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam CLK_PERIOD_NS = 10;
    localparam TIMEOUT_NS    = 50_000;
    localparam LOG_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex3/tb_reg_file_32x32.log";
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex3/tb_reg_file_32x32.vcd";

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg         clk;
    reg         WriteEn;
    reg  [4:0]  ReadAddress1, ReadAddress2, WriteAddress;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    //--------------------------------------------------------------------------
    // Golden model
    //--------------------------------------------------------------------------
    reg [31:0] golden [0:31];

    //--------------------------------------------------------------------------
    // Bookkeeping
    //--------------------------------------------------------------------------
    integer log_fd;
    integer test_id;
    integer pass_cnt;
    integer fail_cnt;

    //--------------------------------------------------------------------------
    // DUT
    //--------------------------------------------------------------------------
    reg_file_32x32 dut (
        .clk          (clk),
        .WriteEn      (WriteEn),
        .ReadAddress1 (ReadAddress1),
        .ReadAddress2 (ReadAddress2),
        .WriteAddress (WriteAddress),
        .WriteData    (WriteData),
        .ReadData1    (ReadData1),
        .ReadData2    (ReadData2)
    );

    //--------------------------------------------------------------------------
    // Clock
    //--------------------------------------------------------------------------
    initial clk = 1'b0;
    always  #(CLK_PERIOD_NS/2) clk = ~clk;

    //==========================================================================
    // Logging helpers
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
    // Ghi 1 thanh ghi (sync) + cap nhat golden
    //==========================================================================
    task rf_write;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            WriteAddress = addr;
            WriteData    = data;
            WriteEn      = 1'b1;
            @(posedge clk);
            #1;
            golden[addr] = data;
            @(negedge clk);
            WriteEn = 1'b0;
        end
    endtask

    //==========================================================================
    // Ghi voi WriteEn=0 -> golden khong doi
    //==========================================================================
    task rf_write_disabled;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            WriteAddress = addr;
            WriteData    = data;
            WriteEn      = 1'b0;
            @(posedge clk);
            #1;
            // golden khong cap nhat
            @(negedge clk);
        end
    endtask

    //==========================================================================
    // Kiem tra 1 port doc
    //==========================================================================
    task check_read1;
        input [4:0]      addr;
        input [8*64-1:0] tag;
        begin
            ReadAddress1 = addr;
            #1;
            test_id = test_id + 1;
            if (ReadData1 === golden[addr]) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  R1 addr=%0d data=%h  (%0s)",
                         $time, test_id, addr, ReadData1, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  R1 addr=%0d data=%h  (%0s)",
                        $time, test_id, addr, ReadData1, tag);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  R1 addr=%0d got=%h exp=%h  (%0s)",
                         $time, test_id, addr, ReadData1, golden[addr], tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  R1 addr=%0d got=%h exp=%h  (%0s)",
                        $time, test_id, addr, ReadData1, golden[addr], tag);
            end
        end
    endtask

    task check_read2;
        input [4:0]      addr;
        input [8*64-1:0] tag;
        begin
            ReadAddress2 = addr;
            #1;
            test_id = test_id + 1;
            if (ReadData2 === golden[addr]) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  R2 addr=%0d data=%h  (%0s)",
                         $time, test_id, addr, ReadData2, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  R2 addr=%0d data=%h  (%0s)",
                        $time, test_id, addr, ReadData2, tag);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  R2 addr=%0d got=%h exp=%h  (%0s)",
                         $time, test_id, addr, ReadData2, golden[addr], tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  R2 addr=%0d got=%h exp=%h  (%0s)",
                        $time, test_id, addr, ReadData2, golden[addr], tag);
            end
        end
    endtask

    //==========================================================================
    // Kiem tra ca 2 port cung luc voi 2 dia chi khac nhau
    //==========================================================================
    task check_dual_read;
        input [4:0]      a1, a2;
        input [8*64-1:0] tag;
        reg ok1, ok2;
        begin
            ReadAddress1 = a1;
            ReadAddress2 = a2;
            #1;
            ok1 = (ReadData1 === golden[a1]);
            ok2 = (ReadData2 === golden[a2]);
            test_id = test_id + 1;
            if (ok1 && ok2) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  DUAL a1=%0d d1=%h  a2=%0d d2=%h  (%0s)",
                         $time, test_id, a1, ReadData1, a2, ReadData2, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  DUAL a1=%0d d1=%h  a2=%0d d2=%h  (%0s)",
                        $time, test_id, a1, ReadData1, a2, ReadData2, tag);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  DUAL got(d1=%h d2=%h) exp(d1=%h d2=%h)  (%0s)",
                         $time, test_id, ReadData1, ReadData2,
                         golden[a1], golden[a2], tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  DUAL got(d1=%h d2=%h) exp(d1=%h d2=%h)  (%0s)",
                        $time, test_id, ReadData1, ReadData2,
                        golden[a1], golden[a2], tag);
            end
        end
    endtask

    //==========================================================================
    // Test cases
    //==========================================================================

    // TC1: ghi tuan tu 32 thanh ghi, doc lai qua ca 2 port
    task tc_seq_write_read;
        integer i;
        begin
            tb_section("TC1 : ghi tuan tu 32 thanh ghi, doc qua 2 port");
            for (i = 0; i < 32; i = i + 1)
                rf_write(i[4:0], 32'hA5A5_0000 + i);
            for (i = 0; i < 32; i = i + 1) begin
                check_read1(i[4:0], "seq R1");
                check_read2(i[4:0], "seq R2");
            end
        end
    endtask

    // TC2: read-during-write - doc dia chi vua ghi sau 1 chu ky
    task tc_read_during_write;
        begin
            tb_section("TC2 : read-during-write, sync-write + async-read");
            // Ghi gia tri moi vao reg 7
            rf_write(5'd7, 32'hDEAD_BEEF);
            // Doc ngay sau khi ghi
            check_read1(5'd7, "ngay sau ghi");
            // Ghi reg 15 va doc lai
            rf_write(5'd15, 32'h1234_5678);
            check_read2(5'd15, "ngay sau ghi (R2)");
        end
    endtask

    // TC3: WriteEn=0 -> gia tri cu giu nguyen
    task tc_write_disabled;
        begin
            tb_section("TC3 : WriteEn=0 khong ghi");
            // Ghi gia tri biet truoc vao reg 20
            rf_write(5'd20, 32'hCAFE_BABE);
            check_read1(5'd20, "truoc khi disabled write");
            // Co gang ghi gia tri khac voi WriteEn=0
            rf_write_disabled(5'd20, 32'h0000_0000);
            check_read1(5'd20, "sau disabled write (phai giu cu)");
        end
    endtask

    // TC4: doc 2 dia chi khac nhau cung luc
    task tc_dual_port_independent;
        begin
            tb_section("TC4 : 2 port doc doc lap voi 2 dia chi khac nhau");
            rf_write(5'd3,  32'h1111_1111);
            rf_write(5'd25, 32'h2222_2222);
            check_dual_read(5'd3, 5'd25, "3 va 25");
            check_dual_read(5'd25, 5'd3, "25 va 3 (doi cho)");
        end
    endtask

    // TC5: ngau nhien 50 lan ghi + doc
    task tc_random;
        integer i;
        reg [4:0]  ra, wa;
        reg [31:0] wd;
        begin
            tb_section("TC5 : ngau nhien 50 lan ghi + doc");
            for (i = 0; i < 50; i = i + 1) begin
                wa = $random & 5'h1F;
                wd = {$random, $random};
                rf_write(wa, wd);
                ra = $random & 5'h1F;
                check_read1(ra, "random R1");
                ra = $random & 5'h1F;
                check_read2(ra, "random R2");
            end
        end
    endtask

    //==========================================================================
    // Main
    //==========================================================================
    initial begin : main
        integer k;
        log_fd   = $fopen(LOG_PATH, "w");
        test_id  = 0;
        pass_cnt = 0;
        fail_cnt = 0;
        WriteEn      = 1'b0;
        WriteAddress = 5'd0;
        WriteData    = 32'd0;
        ReadAddress1 = 5'd0;
        ReadAddress2 = 5'd0;

        for (k = 0; k < 32; k = k + 1)
            golden[k] = 32'd0;   // DUT khoi tao la x, bat dau bang ghi truoc roi doc

        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_reg_file_32x32);

        if (log_fd == 0)
            $display("WARN: cannot open log file, tiep tuc khong ghi log file");

        tb_log("==================================================");
        tb_log("  reg_file_32x32 : tb start");
        tb_log("==================================================");

        tc_seq_write_read();
        tc_read_during_write();
        tc_write_disabled();
        tc_dual_port_independent();
        tc_random();

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
