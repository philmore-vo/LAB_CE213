//==============================================================================
// File         : tb_sp_ram_128x8_wave.v
// Description  : Testbench cau 5.1 - mo hinh quan sat dang song.
//                Khong self-check, chi phat stimulus + dump VCD + $monitor
//                de quan sat bus inout data (gia tri khi ghi/doc va Z khi
//                idle) trong ModelSim.
//==============================================================================
`timescale 1ns/1ps

module tb_sp_ram_128x8_wave;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam CLK_PERIOD_NS = 10;
    localparam TIMEOUT_NS    = 5_000;
    localparam VCD_PATH = "D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex5/tb_sp_ram_128x8_wave.vcd";

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

    // TB chi drive data khi dang ghi (wr_e=1 va cs=1); con lai tha Z
    assign data = (cs && wr_e) ? drv_data : 8'bz;

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

    //--------------------------------------------------------------------------
    // Helper
    //--------------------------------------------------------------------------
    task idle;
        begin
            @(negedge clock);
            cs       = 1'b0;
            wr_e     = 1'b0;
            oe       = 1'b0;
            drv_data = 8'h00;
        end
    endtask

    task do_write;
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
            @(negedge clock);
            cs       = 1'b0;
            wr_e     = 1'b0;
        end
    endtask

    task do_read;
        input [6:0] a;
        begin
            @(negedge clock);
            cs       = 1'b1;
            wr_e     = 1'b0;
            oe       = 1'b1;
            addr     = a;
            drv_data = 8'h00;  // TB nha tri-state vi wr_e=0
            @(posedge clock);
            #1;                // cho rdata propagate -> data
            @(negedge clock);
            cs       = 1'b0;
            oe       = 1'b0;
        end
    endtask

    //--------------------------------------------------------------------------
    // Stimulus
    //--------------------------------------------------------------------------
    initial begin
        $dumpfile(VCD_PATH);
        $dumpvars(0, tb_sp_ram_128x8_wave);
        $monitor("MON t=%0t ns  cs=%b wr_e=%b oe=%b  addr=%h  data=%h",
                 $time, cs, wr_e, oe, addr, data);

        // Khoi tao
        cs       = 1'b0;
        wr_e     = 1'b0;
        oe       = 1'b0;
        addr     = 7'd0;
        drv_data = 8'h00;

        // Ghi mot vai dia chi
        do_write(7'd0,  8'hA5);
        do_write(7'd1,  8'h5A);
        do_write(7'd63, 8'hF0);
        do_write(7'd127,8'h0F);

        // Doc lai -> data co gia tri tren bus
        do_read(7'd0);
        do_read(7'd1);
        do_read(7'd63);
        do_read(7'd127);

        // Quan sat tri-state: cs=0 -> data = Z
        idle();
        repeat (2) @(posedge clock);

        // wr_e=0 va oe=0 -> data = Z
        @(negedge clock);
        cs   = 1'b1;
        wr_e = 1'b0;
        oe   = 1'b0;
        addr = 7'd10;
        repeat (2) @(posedge clock);

        idle();
        repeat (2) @(posedge clock);

        $display("[%0t ns] INFO: tb_sp_ram_128x8_wave finished", $time);
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
