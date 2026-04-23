//==============================================================================
// File         : tb_counter4_wave.v
// Description  : Testbench cau 2.1 - mo hinh quan sat dang song cho counter4.
//                Khong self-check, chi phat stimulus + dump VCD va $monitor
//                de xem wave trong ModelSim.
//==============================================================================
`timescale 1ns/1ps

module tb_counter4_wave;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam CLK_PERIOD_NS = 10;
    localparam TIMEOUT_NS    = 2_000;
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex2/tb_counter4_wave.vcd";

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg        clock;
    reg        reset_n;
    reg        enable;
    reg        up_down;
    wire [3:0] q_out;

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

    //--------------------------------------------------------------------------
    // Stimulus - chi de quan sat wave, khong co assert
    //--------------------------------------------------------------------------
    initial begin
        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_counter4_wave);
        $monitor("MON t=%0t ns  rst_n=%b en=%b up_down=%b  q_out=%h",
                 $time, reset_n, enable, up_down, q_out);

        // Khoi tao
        reset_n = 1'b0;
        enable  = 1'b0;
        up_down = 1'b0;

        // Giu reset 2 chu ky
        repeat (2) @(posedge clock);
        @(negedge clock);
        reset_n = 1'b1;

        // Dem len 20 chu ky -> rollover F->0
        enable  = 1'b1;
        up_down = 1'b0;
        repeat (20) @(posedge clock);

        // Tat enable 5 chu ky -> q_out giu nguyen
        @(negedge clock);
        enable = 1'b0;
        repeat (5) @(posedge clock);

        // Dem xuong 20 chu ky -> rollover 0->F
        @(negedge clock);
        enable  = 1'b1;
        up_down = 1'b1;
        repeat (20) @(posedge clock);

        // Async reset giua chu ky (khong cho canh clock)
        #3 reset_n = 1'b0;
        #7 reset_n = 1'b1;

        // Tiep tuc vai chu ky sau async reset
        repeat (5) @(posedge clock);

        $display("[%0t ns] INFO: tb_counter4_wave finished", $time);
        $finish;
    end

    //--------------------------------------------------------------------------
    // Watchdog
    //--------------------------------------------------------------------------
    initial begin
        #TIMEOUT_NS;
        $display("[%0t ns] FATAL: simulation timeout (%0d ns)", $time, TIMEOUT_NS);
        $finish;
    end

endmodule
