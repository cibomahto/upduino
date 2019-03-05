import argparse

parser = argparse.ArgumentParser(description='Create some test data for an LED screen')
parser.add_argument('-x', dest='xRes', type=int, default=29, help='Screen width, in pixels')
parser.add_argument('-y', dest='yRes', type=int, default=30, help='Screen height, in pixels')

args=parser.parse_args()

out = open('test_data.list','w')

even = True

for x in range(0,args.xRes):
    for y in range(0,args.yRes):
        red = 0
        green = 0
        blue = 0

        if (x == y):
            red = 255
            green = 255
            blue = 255
            print(x,y, x==y)

        out.write('%02x'%(red))
        even = not even
        if(even):
            out.write(' ')

        out.write('%02x'%(green))
        even = not even
        if(even):
            out.write(' ')

        out.write('%02x'%(blue))
        even = not even
        if(even):
            out.write(' ')

#    if(inputValue % 16 == 15):
#        out.write('\n')
