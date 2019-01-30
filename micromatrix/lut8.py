'''
module lut(count_out, angle); 

input [2:0] count_out; 
output [11:0] angle; 
reg [11:0] angle; 

always @(count_out) 

case (count_out) 

3'b000: angle=12'b001000000000; //0 45 45 
3'b001: angle=12'b000100101110; //1 26.54 26.57 
3'b010: angle=12'b000010100000; //2 14.06 14.036 
3'b011: angle=12'b000001010001; //3 7.12 7.13 
3'b100: angle=12'b000000101001; //4 3.604 3.576 
3'b101: angle=12'b000000010100; //5 1.76 1.79 
3'b110: angle=12'b000000001010; //6 0.88 0.9 
3'b111: angle=12'b000000000101; //7 0.44 0.45 
default: angle=12'b001000000000; //default 0 

endcase 

endmodule
'''

header = '''
module correction_lut_8(value, corrected); 

input [7:0] value; 
output [7:0] corrected; 
reg [7:0] corrected; 

always @(value) 

case (value) 
'''

footer = '''

endcase 

endmodule

'''


out = open('correction_lut_8.v','w')
out_ram = open('lut8.list', 'w')

out.write(header)

for val in range(0,256):
    corrected = int(255*pow(val/255.0,1.8))

    out.write("%i: corrected=%i;\n" % (val,corrected))

    out_ram.write("%02x" % corrected)

    if(val%8 == 7):
        out_ram.write("\n")
    else:
        out_ram.write(" ")

out.write(footer)
