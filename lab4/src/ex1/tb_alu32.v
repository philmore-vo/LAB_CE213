//==============================================================================
// File         : tb_alu32.v
// Description  : Testbench cho ALU 32-bit (Lab4 cau 1).
//                Dung $display va $monitor theo yeu cau de. Kiem tra ca 8
//                op-code voi 2 cap (A,B) moi op (truc quan + bien),
//                so sanh Y voi gia tri ky vong tinh boi testbench.
//==============================================================================
`timescale 1ns/1ps

module tb_alu32;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam TIMEOUT_NS = 5_000;
    localparam LOG_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex1/tb_alu32.log";
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex1/tb_alu32.vcd";

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg  [31:0] A, B;
    reg         M, S1, S0;
    wire [31:0] Y;

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
    alu32 dut (
        .A (A), .B (B),
        .M (M), .S1(S1), .S0(S0),
        .Y (Y)
    );

    //==========================================================================
    // Op-code -> ten (de log cho de doc)
    //==========================================================================
    function [8*10-1:0] op_name;
        input [2:0] op;
        begin
            case (op)
                3'b000 : op_name = "CPLA      ";
                3'b001 : op_name = "AND       ";
                3'b010 : op_name = "XOR       ";
                3'b011 : op_name = "OR        ";
                3'b100 : op_name = "DECA      ";
                3'b101 : op_name = "ADD       ";
                3'b110 : op_name = "SUB       ";
                3'b111 : op_name = "INCA      ";
                default: op_name = "UNK       ";
            endcase
        end
    endfunction

    //==========================================================================
    // Tinh gia tri ky vong cho 1 op-code
    //==========================================================================
    function [31:0] expected;
        input [2:0]  op;
        input [31:0] a, b;
        begin
            case (op)
                3'b000 : expected = ~a;
                3'b001 : expected =  a & b;
                3'b010 : expected =  a ^ b;
                3'b011 : expected =  a | b;
                3'b100 : expected =  a - 32'd1;
                3'b101 : expected =  a + b;
                3'b110 : expected =  a - b;
                3'b111 : expected =  a + 32'd1;
                default: expected = 32'hxxxx_xxxx;
            endcase
        end
    endfunction

    //==========================================================================
    // Task: ap 1 vector, cho on dinh, so sanh voi expected
    //==========================================================================
    task apply_and_check;
        input [2:0]  op;
        input [31:0] a_val, b_val;
        reg   [31:0] exp;
        begin
            {M, S1, S0} = op;
            A = a_val;
            B = b_val;
            #1;                                     // cho combinational on dinh
            exp     = expected(op, a_val, b_val);
            test_id = test_id + 1;
            if (Y === exp) begin
                pass_cnt = pass_cnt + 1;
                $display("[%0t ns] PASS #%0d  %s A=%h B=%h -> Y=%h (exp=%h)",
                         $time, test_id, op_name(op), a_val, b_val, Y, exp);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] PASS #%0d  %s A=%h B=%h -> Y=%h (exp=%h)",
                        $time, test_id, op_name(op), a_val, b_val, Y, exp);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[%0t ns] FAIL #%0d  %s A=%h B=%h -> Y=%h (exp=%h)",
                         $time, test_id, op_name(op), a_val, b_val, Y, exp);
                if (log_fd)
                    $fdisplay(log_fd,
                        "[%0t ns] FAIL #%0d  %s A=%h B=%h -> Y=%h (exp=%h)",
                        $time, test_id, op_name(op), a_val, b_val, Y, exp);
            end
            #4;                                     // gian cach giua cac vector
        end
    endtask

    //==========================================================================
    // Test cases: moi op-code 2 cap (A,B)
    //==========================================================================
    task run_all_ops;
        integer op;
        begin
            for (op = 0; op < 8; op = op + 1) begin
                // Cap 1: truc quan
                apply_and_check(op[2:0], 32'h0000_000F, 32'h0000_00F0);
                // Cap 2: bien / rollover
                apply_and_check(op[2:0], 32'hFFFF_FFFF, 32'h0000_0001);
            end
        end
    endtask

    task run_random_ops;
        integer i;
        reg [31:0] ra, rb;
        reg [2:0]  rop;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                ra  = {$random, $random} & 32'hFFFF_FFFF;
                rb  = {$random, $random} & 32'hFFFF_FFFF;
                rop = $random & 3'h7;
                apply_and_check(rop, ra, rb);
            end
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
        {M, S1, S0} = 3'b000;
        A = 32'b0;
        B = 32'b0;

        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_alu32);

        // Theo yeu cau de: dung $monitor de quan sat
        $monitor("MON  t=%0t ns  M=%b S1=%b S0=%b  A=%h  B=%h  Y=%h",
                 $time, M, S1, S0, A, B, Y);

        if (log_fd == 0)
            $display("WARN: cannot open log file, tiep tuc khong ghi log file");

        $display("==================================================");
        $display("  alu32 : tb start");
        $display("==================================================");
        if (log_fd) begin
            $fdisplay(log_fd, "==================================================");
            $fdisplay(log_fd, "  alu32 : tb start");
            $fdisplay(log_fd, "==================================================");
        end

        run_all_ops();
        run_random_ops();

        $display("==================================================");
        $display("[%0t ns] SUMMARY  total=%0d  pass=%0d  fail=%0d",
                 $time, pass_cnt + fail_cnt, pass_cnt, fail_cnt);
        if (log_fd) begin
            $fdisplay(log_fd, "==================================================");
            $fdisplay(log_fd,
                "[%0t ns] SUMMARY  total=%0d  pass=%0d  fail=%0d",
                $time, pass_cnt + fail_cnt, pass_cnt, fail_cnt);
        end

        if (fail_cnt == 0) begin
            $display("RESULT : ALL TESTS PASSED");
            if (log_fd) $fdisplay(log_fd, "RESULT : ALL TESTS PASSED");
        end else begin
            $display("RESULT : TEST FAILURES DETECTED");
            if (log_fd) $fdisplay(log_fd, "RESULT : TEST FAILURES DETECTED");
        end

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
