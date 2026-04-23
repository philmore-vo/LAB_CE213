//==============================================================================
// File         : tb_sp_ram_128x8_self.v
// Description  : Self-checking testbench cau 5.2 cho sp_ram_128x8.
//                Xu ly inout bus: TB drive data khi ghi, tha Z khi doc/idle;
//                DUT drive data khi doc (cs=1, wr_e=0, oe=1).
//                Kiem tra: ghi/doc tuan tu 128 byte, bien, tri-state khi
//                cs=0 va oe=0, va 50 giao dich ngau nhien.
//==============================================================================
`timescale 1ns/1ps

module tb_sp_ram_128x8_self;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam CLK_PERIOD_NS = 10;
    localparam TIMEOUT_NS    = 50_000;
    localparam LOG_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex5/tb_sp_ram_128x8_self.log";
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex5/tb_sp_ram_128x8_self.vcd";

    //--------------------------------------------------------------------------
    // Tin hieu
    //--------------------------------------------------------------------------
    reg       clock;
    reg       cs;
    reg       wr_e;
    reg       oe;
    reg [6:0] addr;
    reg [7:0] drv_data;
    wire [7:0] data;

    assign data = (cs && wr_e) ? drv_data : 8'bz;

    //--------------------------------------------------------------------------
    // Golden
    //--------------------------------------------------------------------------
    reg [7:0] gold [0:127];

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
    sp_ram_128x8 dut (
        .clock (clock),
        .cs    (cs),
        .wr_e  (wr_e),
        .oe    (oe),
        .addr  (addr),
        .data  (data)
    );

    //--------------------------------------------------------------------------
    // Clock
    //--------------------------------------------------------------------------
    initial clock = 1'b0;
    always  #(CLK_PERIOD_NS/2) clock = ~clock;

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
    // Transaction tasks
    //==========================================================================
    task ram_write;
        input [6:0] a;
        input [7:0] d;
        begin
            @(negedge clock);
            cs       = 1'b1;
            wr_e     = 1'b1;
            oe       = 1'b0;
            addr     = a;
            drv_data = d;
            @(posedge clock);
            #1;
            gold[a] = d;
            @(negedge clock);
            cs   = 1'b0;
            wr_e = 1'b0;
        end
    endtask

    task ram_read_check;
        input [6:0]      a;
        input [8*64-1:0] tag;
        begin
            @(negedge clock);
            cs       = 1'b1;
            wr_e     = 1'b0;
            oe       = 1'b1;
            addr     = a;
            drv_data = 8'h00;   // TB nha Z vi wr_e=0
            @(posedge clock);
            #1;                  // cho DUT drive data
            test_id = test_id + 1;
            if (data === gold[a]) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  R addr=%0d data=%h  (%0s)",
                         $time, test_id, a, data, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  R addr=%0d data=%h  (%0s)",
                        $time, test_id, a, data, tag);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  R addr=%0d got=%h exp=%h  (%0s)",
                         $time, test_id, a, data, gold[a], tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  R addr=%0d got=%h exp=%h  (%0s)",
                        $time, test_id, a, data, gold[a], tag);
            end
            @(negedge clock);
            cs = 1'b0;
            oe = 1'b0;
        end
    endtask

    //==========================================================================
    // Kiem tra bus phai la Z (tri-state)
    //==========================================================================
    task expect_high_z;
        input [8*64-1:0] tag;
        begin
            test_id = test_id + 1;
            if (data === 8'bz) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  Z-bus  (%0s)",
                         $time, test_id, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  Z-bus  (%0s)",
                        $time, test_id, tag);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  bus khong phai Z, data=%h  (%0s)",
                         $time, test_id, data, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  bus khong phai Z, data=%h  (%0s)",
                        $time, test_id, data, tag);
            end
        end
    endtask

    //==========================================================================
    // Test cases
    //==========================================================================

    // TC1: ghi toan bo 128 byte + doc lai
    task tc_full_sweep;
        integer i;
        begin
            tb_section("TC1 : ghi/doc toan bo 128 byte");
            for (i = 0; i < 128; i = i + 1)
                ram_write(i[6:0], (i[7:0] ^ 8'hA5));
            for (i = 0; i < 128; i = i + 1)
                ram_read_check(i[6:0], "sweep");
        end
    endtask

    // TC2: cs=0 khi ghi -> RAM khong doi
    task tc_cs_gates_write;
        begin
            tb_section("TC2 : cs=0 khi ghi khong thay doi RAM");
            ram_write(7'd50, 8'hDE);
            ram_read_check(7'd50, "truoc khi cs=0 write");
            // Thu ghi khi cs=0
            @(negedge clock);
            cs       = 1'b0;
            wr_e     = 1'b1;
            addr     = 7'd50;
            drv_data = 8'hAD;
            @(posedge clock);
            #1;
            @(negedge clock);
            cs   = 1'b0;
            wr_e = 1'b0;
            // golden khong doi -> phai van la DE
            ram_read_check(7'd50, "sau cs=0 write (phai la DE)");
        end
    endtask

    // TC3: oe=0 -> bus phai la Z
    task tc_oe_tri_state;
        begin
            tb_section("TC3 : oe=0 khi doc -> bus Z");
            // Set up read nhung oe=0
            @(negedge clock);
            cs       = 1'b1;
            wr_e     = 1'b0;
            oe       = 1'b0;
            addr     = 7'd20;
            drv_data = 8'h00;
            @(posedge clock);
            #1;
            expect_high_z("cs=1 wr_e=0 oe=0");
            @(negedge clock);
            cs = 1'b0;

            // cs=0 -> bus cung phai Z
            @(negedge clock);
            cs       = 1'b0;
            wr_e     = 1'b0;
            oe       = 1'b1;
            drv_data = 8'h00;
            @(posedge clock);
            #1;
            expect_high_z("cs=0 oe=1");
            @(negedge clock);
        end
    endtask

    // TC4: ghi roi doc ngay lap tuc cung dia chi
    task tc_back_to_back;
        begin
            tb_section("TC4 : ghi roi doc ngay lap tuc");
            ram_write(7'd99, 8'hBE);
            ram_read_check(7'd99, "back-to-back");
        end
    endtask

    // TC5: ngau nhien 50 giao dich
    task tc_random;
        integer i;
        reg [6:0] a;
        reg [7:0] d;
        begin
            tb_section("TC5 : ngau nhien 50 giao dich");
            for (i = 0; i < 50; i = i + 1) begin
                a = $random & 7'h7F;
                d = $random & 8'hFF;
                ram_write(a, d);
                ram_read_check(a, "random");
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
        cs       = 1'b0;
        wr_e     = 1'b0;
        oe       = 1'b0;
        addr     = 7'd0;
        drv_data = 8'h00;

        for (k = 0; k < 128; k = k + 1)
            gold[k] = 8'd0;

        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_sp_ram_128x8_self);

        if (log_fd == 0)
            $display("WARN: cannot open log file, tiep tuc khong ghi log file");

        tb_log("==================================================");
        tb_log("  sp_ram_128x8 : tb start (self-checking)");
        tb_log("==================================================");

        tc_full_sweep();
        tc_cs_gates_write();
        tc_oe_tri_state();
        tc_back_to_back();
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
