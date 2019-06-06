import argparse

parser = argparse.ArgumentParser(description='Create a lookup table from X bits to Y bits, using a power function')
parser.add_argument('-i', dest='inputBits', type=int, default=8, help='Number of input bits')
parser.add_argument('-o', dest='outputBits', type=int, default=16, help='Number of output bits')
parser.add_argument('-e', dest='exponent', type=float, default=1.8, help='Lookup table exponent')

args=parser.parse_args()

inputMax = pow(2,args.inputBits)-1
outputMax = pow(2,args.outputBits)-1

print(inputMax)
print(outputMax)

out = open('lut_%d_to_%d_pow_%0.2f.list'%(args.inputBits,args.outputBits,args.exponent),'w')

formatNibbles = (args.outputBits+3)/4
formatString = '%0'+'%dx '%(formatNibbles)

for inputValue in range(0, (inputMax+1)):
    outputValue = int(outputMax*pow(inputValue/float(inputMax),args.exponent))

    out.write(formatString%(outputValue))

    if(inputValue % 16 == 15):
        out.write('\n')
