import argparse

parser = argparse.ArgumentParser(description='Create some test data for an LED screen')
parser.add_argument('-c', dest='count', type=int, default=2688, help='channel count')

args=parser.parse_args()

out = open('test_data16.list','w')

for i in range(0,args.count):
    red = 0
    green = 0
    blue = 0

    red = i*3 + 0
    green = i*3 + 1
    blue = i*3 + 2

#    if (i%3==0):
#        red = 65535

#    if (i%3==1):
#        green = 65535

#    if (i%3==2):
#        blue = 65535

    out.write('%04x '%(red))
    out.write('%04x '%(green))
    out.write('%04x  '%(blue))

    if(i % 16 == 15):
        out.write('\n')
