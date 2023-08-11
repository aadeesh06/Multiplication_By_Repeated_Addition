module Mul_datapath(eqz, LdA, LdB, LdP, clrP, decB, data_in, clk);
    input LdA, LdB, LdP, clrP, decB, clk;
    input [15:0] data_in;
    output eqz;
    wire [15:0] x, y, z, b_out, bus;
    assign bus = data_in;
    PIPO1 A(x, bus, LdA, clk);
    PIPO2 P(y, z, LdP, clrP, clk);
    CNTR B(b_out, bus, LdB, decB, clk);
    ADD AD(z, x, y);
    EQZ comp(eqz, b_out);
endmodule

module ADD(out , in1, in2);
    input [15:0] in1, in2;
    output reg [15:0] out;
    always @(*)
        out = in1 + in2;
endmodule

module PIPO1(d_out, d_in, ld, clk);
    input [15:0] d_in;
    input ld, clk;
    output reg [15:0] d_out;
    always @(posedge clk)
        if(ld)
            d_out <= d_in;
endmodule

module PIPO2(d_out, d_in, ld, clr, clk);
    input [15:0] d_in;
    input clr, clk, ld;
    output reg [15:0] d_out;
    always @(posedge clk)
        if(clr)
            d_out <= 16'b0;
        else if(ld)
            d_out <= d_in;
endmodule

module EQZ(eqz, data);
    input [15:0] data;
    output eqz;
    assign eqz = (data == 0); // if B == 0, then eqz i.e. equality to z is zero
endmodule

module CNTR (d_out, d_in, ld, dec, clk);
    input [15:0] d_in;
    input ld, dec, clk;
    output reg [15:0] d_out;
    always @(posedge clk)
    begin
        if(ld)
            d_out <= d_in;
        else if(dec)
            d_out <= d_out - 1;
    end
endmodule



module controller(LdA, LdB, LdP, clrP, decB, done, clk, eqz, start);

// The control path
    input clk, eqz, start;
    output reg LdA, LdB, LdP, clrP, decB, done;

    reg [2:0] state;
    parameter s0 = 3'b000, s1 = 3'b001, s2 = 3'b010, s3 = 3'b011, s4 = 3'b100;
    always @(posedge clk)
        begin
            case (state)
                s0 : if(start) 
                        state <= s1;
                s1 : state <= s2;
                s2 : state <= s3;
                s3 : #2 if(eqz)         
                            state <= s4;
                s4 : state <= s4;
                default : state <= s0;
            endcase    
        end
    always @(state)
    begin
            case (state)
                s0 : begin 
                        #1 LdA = 0; LdB = 0; LdP = 0; clrP = 0; decB = 0; 
                     end
                s1 : begin 
                        #1 LdA = 1;
                     end
                s2 : begin 
                      #1 LdA = 0; LdB = 1; clrP = 1;
                     end
                s3 : begin 
                      #1 LdB = 0; LdP = 1; clrP = 0; decB = 1;
                     end
                s4 : begin
                      #1 done = 1; LdB = 0; LdP = 0; decB = 0;
                     end 
                default : begin 
                            #1 LdA = 0; LdB = 0; LdP = 0; clrP = 0; decB = 0;
                          end
            endcase 
    end
endmodule