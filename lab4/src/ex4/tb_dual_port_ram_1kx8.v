//==============================================================================
// File         : tb_dual_port_ram_1kx8.v
// Description  : Self-checking testbench cho dual_port_ram_1kx8 (Lab4 cau 4).
//                Duy tri golden 1024 byte, test:
//                  - Ghi/doc dia chi bien (0, 1023)
//                  - Ghi mau mem[i]=i[7:0] cho 0..255 roi doc lai
//                  - WriteEn=0 khong anh huong du lieu
//                  - ReadEn=0 giu ReadData cu (gated read)
//                  - Ngau nhien 100 giao dich, so voi golden
//==============================================================================
`timescale 1ns/1ps

module tb_dual_port_ram_1kx8;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam CLK_PERIOD_NS = 10;
    localparam TIMEOUT_NS    = 100_000;
    localparam LOG_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex4/tb_dual_port_ram_1kx8.log";
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex4/tb_dual_port_ram_1kx8.vcd";

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg        clk;
    reg        WriteEn, ReadEn;
    reg  [9:0] Address;
    reg  [7:0] WriteData;
    wire [7:0] ReadData;

    //--------------------------------------------------------------------------
    // Golden
    //--------------------------------------------------------------------------
    reg [7:0] gold [0:1023];

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
    dual_port_ram_1kx8 dut (
        .clk       (clk),
        .WriteEn   (WriteEn),
        .ReadEn    (ReadEn),
        .Address   (Address),
        .WriteData (WriteData),
        .ReadData  (ReadData)
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
    // Ghi 1 byte (sync)
    //==========================================================================
    task mem_write;
        input [9:0] addr;
        input [7:0] data;
        begin
            @(negedge clk);
            Address   = addr;
            WriteData = data;
            WriteEn   = 1'b1;
            ReadEn    = 1'b0;
            @(posedge clk);
            #1;
            gold[addr] = data;
            @(negedge clk);
            WriteEn = 1'b0;
        end
    endtask

    //==========================================================================
    // Doc 1 byte va kiem tra (sync read - data co gia tri sau canh len)
    //==========================================================================
    task mem_read_check;
        input [9:0]      addr;
        input [8*64-1:0] tag;
        begin
            @(negedge clk);
            Address = addr;
            ReadEn  = 1'b1;
            WriteEn = 1'b0;
            @(posedge clk);
            #1;
            test_id = test_id + 1;
            if (ReadData === gold[addr]) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  R  addr=%0d  data=%h  (%0s)",
                         $time, test_id, addr, ReadData, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  R  addr=%0d  data=%h  (%0s)",
                        $time, test_id, addr, ReadData, tag);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  R  addr=%0d  got=%h exp=%h  (%0s)",
                         $time, test_id, addr, ReadData, gold[addr], tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  R  addr=%0d  got=%h exp=%h  (%0s)",
                        $time, test_id, addr, ReadData, gold[addr], tag);
            end
            @(negedge clk);
            ReadEn = 1'b0;
        end
    endtask

    //==========================================================================
    // Test cases
    //==========================================================================

    // TC1: bien Address 0 va 1023
    task tc_boundary;
        begin
            tb_section("TC1 : bien addr=0 va addr=1023");
            mem_write(10'd0,    8'hAA);
            mem_write(10'd1023, 8'h55);
            mem_read_check(10'd0,    "addr=0");
            mem_read_check(10'd1023, "addr=1023");
        end
    endtask

    // TC2: mau mem[i]=i[7:0] cho i=0..255
    task tc_pattern_256;
        integer i;
        begin
            tb_section("TC2 : mem[i] = i[7:0] cho i=0..255");
            for (i = 0; i < 256; i = i + 1)
                mem_write(i[9:0], i[7:0]);
            for (i = 0; i < 256; i = i + 1)
                mem_read_check(i[9:0], "i[7:0]");
        end
    endtask

    // TC3: WriteEn=0 khong doi RAM
    task tc_write_disabled;
        begin
            tb_section("TC3 : WriteEn=0 khong thay doi RAM");
            mem_write(10'd100, 8'hF0);
            mem_read_check(10'd100, "sau ghi F0");
            // Thu ghi khac voi WriteEn=0
            @(negedge clk);
            Address   = 10'd100;
            WriteData = 8'h0F;
            WriteEn   = 1'b0;
            ReadEn    = 1'b0;
            @(posedge clk);
            #1;
            @(negedge clk);
            // golden khong doi
            mem_read_check(10'd100, "sau disabled write (phai la F0)");
        end
    endtask

    // TC4: ReadEn=0 giu ReadData cu
    task tc_read_gated;
        reg [7:0] frozen;
        begin
            tb_section("TC4 : ReadEn=0 giu ReadData cu");
            mem_write(10'd200, 8'h12);
            mem_read_check(10'd200, "set ReadData=12");
            frozen = ReadData;
            // Doi Address ma khong bat ReadEn
            mem_write(10'd201, 8'h34);
            @(negedge clk);
            Address = 10'd201;
            ReadEn  = 1'b0;
            WriteEn = 1'b0;
            @(posedge clk);
            #1;
            test_id = test_id + 1;
            if (ReadData === frozen) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  gated-read  ReadData=%h giu nguyen",
                         $time, test_id, ReadData);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  gated-read  ReadData=%h giu nguyen",
                        $time, test_id, ReadData);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  gated-read  got=%h exp=%h",
                         $time, test_id, ReadData, frozen);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  gated-read  got=%h exp=%h",
                        $time, test_id, ReadData, frozen);
            end
            @(negedge clk);
        end
    endtask

    // TC5: ngau nhien 100 giao dich
    task tc_random;
        integer i;
        reg [9:0] a;
        reg [7:0] d;
        begin
            tb_section("TC5 : ngau nhien 100 giao dich ghi+doc");
            for (i = 0; i < 100; i = i + 1) begin
                a = $random & 10'h3FF;
                d = $random & 8'hFF;
                mem_write(a, d);
                mem_read_check(a, "random");
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
        WriteEn   = 1'b0;
        ReadEn    = 1'b0;
        Address   = 10'd0;
        WriteData = 8'd0;

        for (k = 0; k < 1024; k = k + 1)
            gold[k] = 8'd0;

        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_dual_port_ram_1kx8);

        if (log_fd == 0)
            $display("WARN: cannot open log file, tiep tuc khong ghi log file");

        tb_log("==================================================");
        tb_log("  dual_port_ram_1kx8 : tb start");
        tb_log("==================================================");

        tc_boundary();
        tc_pattern_256();
        tc_write_disabled();
        tc_read_gated();
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
