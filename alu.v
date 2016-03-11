// alu.v
// ~~~~~~~~~~
// Author: Andrew D. Booth
// - 32-bit ALU for UB CSE341 with Kris Schindler

`timescale 1ns/1ns

/**
 * fullAdder
 * Full adder for 1 bit, with carry
 *
 * Outputs
 * sum: zeroth bit of sum of a, b and cin
 * cout: carry out. First bit of sum of a, b, and cin
 *
 * Inputs
 * a: one of the bits to be summed
 * b: one of the bits to be summed
 * cin: carry in. Also summed with a and b
 */
module fullAdder(sum, cout, a, b, cin);
    //Outputs
    output sum;         //Sum
    output cout;        //Carry out
    //Inputs
    input a, b, cin;    //Inputs to be summed
    //Wires
    wire r1, a0, a1, a2;

    /*
     * Sum is determined by XOR-ing inputs together, and then by
     * XOR-ing that output with the carry-in
     */
    xor #3
        xor0(r1, a, b),
        xor1(sum, r1, cin);

    /*
     * Carry-out is determined by OR-ing the ANDs of every
     * combination of input (a, b and cin)
     */
    and #2
        and0(a0, a, b),
        and1(a1, a, cin),
        and2(a2, b, cin);
    or #2 
        or0(cout, a0, a1, a2);
endmodule



/**
 * muxTwo
 * 2-bit Multiplexer
 *
 * Output
 * out: selected data
 *
 * Inputs
 * data0: data 0
 * data1: data 1
 * crtl: 1-bit control. 0 chooses data 0, 1 chooses data 2
 */
module muxTwo(out, data0, data1, crtl);
    //Output
    output out;             //Selected data
    //Inputs
    input data0, data1;     //Data inputs to select from
    input crtl;             //Input that makes the selection
    //Wires
    wire notcrtl, a0, a1;


    not #1 
        not0(notcrtl, crtl);

    //crtl controls the output of these AND gates for the data selection
    and #2
        and0(a0, data0, notcrtl),
        and1(a1, data1, crtl);

    or #2 
        or0(out, a0, a1);
endmodule



/**
 * muxFour
 * 4-bit multiplexer
 * Uses three 2-bit multiplexers
 *
 * Output
 * out: selected data
 *
 * Inputs
 * data[0-3]: data to select from
 * crtl[1:0]: 2-bit control. Used to describe data selection in binary
 */
module muxFour(out, data0, data1, data2, data3, crtl);
    //Output
    output out;                         //Selected data
    //Inputs
    input data0, data1, data2, data3;   //Data inputs to select from
    input [1:0] crtl;                   //Inputs that makes the selection
    //Wires
    wire top, bottom;

    /*
     * Using three 2-bit multiplexers we can make a data selection
     * from four inputs
     */
    muxTwo mux0(top, data0, data1, crtl[0]);
    muxTwo mux1(bottom, data2, data3, crtl[0]);
    muxTwo muxf(out, top, bottom, crtl[1]);
endmodule



/**
 * bitSlice
 * Bit-slice of an ALU
 * Uses fullAdder(), muxTwo() and muxFour()
 *
 * Outputs
 * out: output of the circuit, selected by the opcode
 * set: 0 if a >= b, 1 if a < b. Used for SLT instruction
 * cout: carry out. First bit of sum of a, b, and cin
 *
 * Inputs
 * a: input a
 * b: input b
 * cin: carry in. Summed with a and b
 * less: 0 unless 0th bit; then depends on 31st bit output
 * op[1:0]: 2-bit control for multiplexer
 * sub: 1 bit control for addition/subtraction. 0 if adding, 1 if subtracting
 */
module bitSlice(out, set, cout, a, b, cin, less, op);
    //Outputs
    output out;
    output set;
    output cout;
    //Inputs
    input a, b;
    input cin;
    input less;
    input [2:0] op;
    input sub;
    //Wires
    wire andWire, orWire, notB, subMuxOut;

    and #2 
        theAnd(andWire, a, b);

    or #2 
        theOr(orWire, a, b);

    not #1 
        subNot(notB, b);
    muxTwo subMux(subMuxOut, b, notB, op[2]);
    fullAdder theAdder(set, cout, a, subMuxOut, cin);

    muxFour theMux(out, andWire, orWire, set, less, op[1:0]);
endmodule


/**
 * ALU
 * 32-bit ALU
 * Uses bitSlice()
 * 
 * Outputs
 * zero: outputs a 1 if the value of out is 0
 * out[31:0]: the 32-bit arithmetic result of the operation on a and b
 * overflow: outputs a 1 if there was an overflow error, 0 if not
 * cout: outputs the cout of the 32nd bit
 *
 * Inputs
 * a[31:0]: first 32-bit input. Operand for arithmetic fuctions
 * b[32:0]: second 32-bit input. Operand for arithmetic functions
 * op[2:0]: 3-bit opcode for selecting operation. Opcodes are as follows:
 * - 0: bitwise and (AND)
 * - 1: bitwise or (OR)
 * - 2: ADD
 * - 6: subtract (SUB)
 * - 7: set on less than (SLT)
 */
module ALU(zero, out, overflow, cout, a, b, op);
    //Outputs
    output zero;
    output [31:0] out;
    output overflow;
    output cout;
    //Inputs
    input [31:0] a, b;
    input [2:0] op;

    bitSlice
        bs0(out[0], bit0Set, bit0Cout, a[0], b[0], op[2], slt, op),
        bs1(out[1], bit1Set, bit1Cout, a[1], b[1], bit0Cout, 0, op),
        bs2(out[2], bit2Set, bit2Cout, a[2], b[2], bit1Cout, 0, op),
        bs3(out[3], bit3Set, bit3Cout, a[3], b[3], bit2Cout, 0, op),
        bs4(out[4], bit4Set, bit4Cout, a[4], b[4], bit3Cout, 0, op),
        bs5(out[5], bit5Set, bit5Cout, a[5], b[5], bit4Cout, 0, op),
        bs6(out[6], bit6Set, bit6Cout, a[6], b[6], bit5Cout, 0, op),
        bs7(out[7], bit7Set, bit7Cout, a[7], b[7], bit6Cout, 0, op),
        bs8(out[8], bit8Set, bit8Cout, a[8], b[8], bit7Cout, 0, op),
        bs9(out[9], bit9Set, bit9Cout, a[9], b[9], bit8Cout, 0, op),
        bs10(out[10], bit10Set, bit10Cout, a[10], b[10], bit9Cout, 0, op),
        bs11(out[11], bit11Set, bit11Cout, a[11], b[11], bit10Cout, 0, op),
        bs12(out[12], bit12Set, bit12Cout, a[12], b[12], bit11Cout, 0, op),
        bs13(out[13], bit13Set, bit13Cout, a[13], b[13], bit12Cout, 0, op),
        bs14(out[14], bit14Set, bit14Cout, a[14], b[14], bit13Cout, 0, op),
        bs15(out[15], bit15Set, bit15Cout, a[15], b[15], bit14Cout, 0, op),
        bs16(out[16], bit16Set, bit16Cout, a[16], b[16], bit15Cout, 0, op),
        bs17(out[17], bit17Set, bit17Cout, a[17], b[17], bit16Cout, 0, op),
        bs18(out[18], bit18Set, bit18Cout, a[18], b[18], bit17Cout, 0, op),
        bs19(out[19], bit19Set, bit19Cout, a[19], b[19], bit18Cout, 0, op),
        bs20(out[20], bit20Set, bit20Cout, a[20], b[20], bit19Cout, 0, op),
        bs21(out[21], bit21Set, bit21Cout, a[21], b[21], bit20Cout, 0, op),
        bs22(out[22], bit22Set, bit22Cout, a[22], b[22], bit21Cout, 0, op),
        bs23(out[23], bit23Set, bit23Cout, a[23], b[23], bit22Cout, 0, op),
        bs24(out[24], bit24Set, bit24Cout, a[24], b[24], bit23Cout, 0, op),
        bs25(out[25], bit25Set, bit25Cout, a[25], b[25], bit24Cout, 0, op),
        bs26(out[26], bit26Set, bit26Cout, a[26], b[26], bit25Cout, 0, op),
        bs27(out[27], bit27Set, bit27Cout, a[27], b[27], bit26Cout, 0, op),
        bs28(out[28], bit28Set, bit28Cout, a[28], b[28], bit27Cout, 0, op),
        bs29(out[29], bit29Set, bit29Cout, a[29], b[29], bit28Cout, 0, op),
        bs30(out[30], bit30Set, bit30Cout, a[30], b[30], bit29Cout, 0, op),
        bs31(out[31], bit31Set, cout, a[31], b[31], bit30Cout, 0, op);

    or #2
        zeroOr(zeroOrOut, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7], out[8], out[9], out[10], out[11], out[12], out[13], out[14], out[15], out[16], out[17], out[18], out[19], out[20], out[21], out[22], out[23], out[24], out[25], out[26], out[27], out[28], out[29], out[30], out[31]);

    not #1
        zeroInv(zero, zeroOrOut);

    xor #3 
        sltGate(slt, overflow, bit31Set),
        overflowGate(overflow, bit30Cout, cout);
endmodule


module ALUTester();
    reg [31:0] a, b;
    reg [2:0] op;
    wire zero, overflow, cout;
    wire [31:0] out;

    ALU alu(zero, out, overflow, cout, a, b, op);

    parameter maxSize = 4294967296;
    initial begin
        $monitor($time, ", %b, %d, %d, %d, %d, %d", op, a, b, zero, out, overflow);
        op = 0;
        repeat(1000) begin
            #1000 a = $random % maxSize; b = $random % maxSize;
        end

        op = 1;
        repeat(1000) begin
            #1000 a = $random % maxSize; b = $random % maxSize;
        end

        op = 2;
        repeat(1000) begin
            #1000 a = $random % maxSize; b = $random % maxSize;            
        end

        op = 6;
        repeat(1000) begin
            #1000 a = $random % maxSize; b = $random % maxSize;
        end

        op = 7;
        repeat(1000) begin
            #1000 a = $random % maxSize; b = $random % maxSize;
        end
    end
endmodule





