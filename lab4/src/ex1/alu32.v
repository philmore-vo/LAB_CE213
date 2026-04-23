//==============================================================================
// File         : alu32.v
// Description  : ALU 32-bit theo bang chuc nang trong Lab4 cau 1.
//                Op-code = {M, S1, S0}:
//                   000 : Y = ~A          (Complement A)
//                   001 : Y = A & B       (AND)
//                   010 : Y = A ^ B       (EX-OR)
//                   011 : Y = A | B       (OR)
//                   100 : Y = A - 1       (Decrement A)
//                   101 : Y = A + B       (Add)
//                   110 : Y = A - B       (Subtract)
//                   111 : Y = A + 1       (Increment A)
//==============================================================================
module alu32 (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        M,
    input  wire        S1,
    input  wire        S0,
    output reg  [31:0] Y
);

    always @(*) begin
        case ({M, S1, S0})
            3'b000 : Y = ~A;
            3'b001 : Y =  A & B;
            3'b010 : Y =  A ^ B;
            3'b011 : Y =  A | B;
            3'b100 : Y =  A - 32'd1;
            3'b101 : Y =  A + B;
            3'b110 : Y =  A - B;
            3'b111 : Y =  A + 32'd1;
            default: Y = 32'hxxxx_xxxx;
        endcase
    end

endmodule
