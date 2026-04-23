//==============================================================================
// File         : tb_counter4_self.v
// Description  : Testbench cau 2.2 - self-checking cho counter4.
//                Duy tri mot golden model exp_q cap nhat song song voi DUT,
//                kiem tra q_out === exp_q sau moi canh len clock.
//==============================================================================
`timescale 1ns/1ps

module tb_counter4_self;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam CLK_PERIOD_NS = 10;
    localparam TIMEOUT_NS    = 5_000;
    localparam LOG_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex2/tb_counter4_self.log";
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex2/tb_counter4_self.vcd";

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg        clock;
    reg        reset_n;
    reg        enable;
    reg        up_down;
    wire [3:0] q_out;

    //--------------------------------------------------------------------------
    // Golden model
    //--------------------------------------------------------------------------
    reg [3:0] exp_q;

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
    counter4 dut (
        .clock   (clock),
        .reset_n (reset_n),
        .enable  (enable),
        .up_down (up_down),
        .q_out   (q_out)
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
    // Cap nhat golden model theo cung quy luat voi DUT
    //==========================================================================
    task update_golden;
        begin
            if (!reset_n)
                exp_q = 4'd0;
            else if (enable)
                exp_q = up_down ? (exp_q - 4'd1) : (exp_q + 4'd1);
        end
    endtask

    //==========================================================================
    // Kiem tra sau canh len clock
    //==========================================================================
    task tick_and_check;
        input [8*64-1:0] tag;
        begin
            @(posedge clock);
            update_golden();
            #1;  // cho q_out non-blocking cap nhat
            test_id = test_id + 1;
            if (q_out === exp_q) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  q_out=%h exp=%h  (%0s)",
                         $time, test_id, q_out, exp_q, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  q_out=%h exp=%h  (%0s)",
                        $time, test_id, q_out, exp_q, tag);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  q_out=%h exp=%h  (%0s)",
                         $time, test_id, q_out, exp_q, tag);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  q_out=%h exp=%h  (%0s)",
                        $time, test_id, q_out, exp_q, tag);
            end
        end
    endtask

    //==========================================================================
    // Reset dong bo: ap reset, cho 2 chu ky, nha ra, dong bo golden = 0
    //==========================================================================
    task apply_reset;
        begin
            @(negedge clock);
            reset_n = 1'b0;
            enable  = 1'b0;
            up_down = 1'b0;
            exp_q   = 4'd0;
            repeat (2) @(posedge clock);
            @(negedge clock);
            reset_n = 1'b1;
            #1;
            tb_log("INFO: reset da duoc nha, q_out=0");
        end
    endtask

    //==========================================================================
    // Test cases
    //==========================================================================

    // TC1: dem len 20 chu ky (qua rollover F -> 0)
    task tc_count_up;
        integer i;
        begin
            tb_section("TC1 : dem len 20 chu ky + rollover");
            apply_reset();
            enable  = 1'b1;
            up_down = 1'b0;
            for (i = 0; i < 20; i = i + 1)
                tick_and_check("count up");
        end
    endtask

    // TC2: enable=0 giu gia tri 5 chu ky
    task tc_hold_when_disabled;
        integer i;
        begin
            tb_section("TC2 : enable=0 giu gia tri");
            // Dem them 3 chu ky truoc khi tat enable
            enable  = 1'b1;
            up_down = 1'b0;
            repeat (3) tick_and_check("warm-up up");
            // Tat enable, kiem tra q_out khong doi
            @(negedge clock);
            enable = 1'b0;
            for (i = 0; i < 5; i = i + 1)
                tick_and_check("hold (en=0)");
        end
    endtask

    // TC3: dem xuong 20 chu ky (qua rollover 0 -> F)
    task tc_count_down;
        integer i;
        begin
            tb_section("TC3 : dem xuong 20 chu ky + rollover");
            apply_reset();
            enable  = 1'b1;
            up_down = 1'b1;
            for (i = 0; i < 20; i = i + 1)
                tick_and_check("count down");
        end
    endtask

    // TC4: bat-tat enable xen ke
    task tc_toggle_enable;
        integer i;
        begin
            tb_section("TC4 : bat-tat enable xen ke");
            apply_reset();
            up_down = 1'b0;
            for (i = 0; i < 10; i = i + 1) begin
                @(negedge clock);
                enable = i[0];   // 0,1,0,1,...
                tick_and_check("toggle en");
            end
        end
    endtask

    // TC5: async reset giua chu ky
    task tc_async_reset;
        begin
            tb_section("TC5 : async reset khong cho canh clock");
            apply_reset();
            enable  = 1'b1;
            up_down = 1'b0;
            tick_and_check("warm-up 1");
            tick_and_check("warm-up 2");
            tick_and_check("warm-up 3");
            // Keo reset xuong giua chu ky
            #3 reset_n = 1'b0;
            exp_q = 4'd0;
            #1;
            test_id = test_id + 1;
            if (q_out === exp_q) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  async-reset  q_out=%h",
                         $time, test_id, q_out);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  async-reset  q_out=%h",
                        $time, test_id, q_out);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  async-reset  q_out=%h exp=%h",
                         $time, test_id, q_out, exp_q);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  async-reset  q_out=%h exp=%h",
                        $time, test_id, q_out, exp_q);
            end
            @(negedge clock);
            reset_n = 1'b1;
            #1;
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
        reset_n  = 1'b1;
        enable   = 1'b0;
        up_down  = 1'b0;
        exp_q    = 4'd0;

        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_counter4_self);

        if (log_fd == 0)
            $display("WARN: cannot open log file, tiep tuc khong ghi log file");

        tb_log("==================================================");
        tb_log("  counter4 : tb start (self-checking)");
        tb_log("==================================================");

        tc_count_up();
        tc_hold_when_disabled();
        tc_count_down();
        tc_toggle_enable();
        tc_async_reset();

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
