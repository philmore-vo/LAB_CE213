//==============================================================================
// File         : counter4.v
// Description  : Counter 4-bit (Lab4 cau 2).
//                - clock   : kich canh len
//                - reset_n : bat dong bo, tich cuc thap
//                - enable  : tich cuc cao, cho phep dem
//                - up_down : 0 -> dem len, 1 -> dem xuong
//==============================================================================
module counter4 (
    input  wire       clock,
    input  wire       reset_n,
    input  wire       enable,
    input  wire       up_down,
    output reg  [3:0] q_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            q_out <= 4'd0;
        else if (enable)
            q_out <= up_down ? (q_out - 4'd1) : (q_out + 4'd1);
    end

endmodule
