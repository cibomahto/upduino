#!/usr/bin/python

def array_to_word(value):
    """ Convert an array of 16 integers, representing binary bits, into one integer """
    retval = 0

    for i in range(0,16):
        retval += value[i] << (15 - i)

    return retval


data_stream = []

DATA_COL = 1
CLOCK_COL = 2

# Use rising edges of the clock to sample the data
with open('/home/matt/Desktop/untitled.csv') as data_file:
    line_index = -1
    for line in data_file:
        line_index += 1

        # ignore the header
        if(line_index == 0):
            continue

        line_data = line.split(',')
        clock = int(line_data[CLOCK_COL])
        data = int(line_data[DATA_COL])

        # For the first data line, only record the clock state
        if(line_index == 1):
            last_clock = clock
            continue

        if(clock == 1 and last_clock == 0):
            data_stream.append(data)

        last_clock = clock

MODE_START = 0
MODE_BREAK_AFTER_START = 1
MODE_CONFIG = 2
MODE_BREAK_AFTER_CONFIG = 3
MODE_DATA_LOW = 4
MODE_BREAK_AFTER_DATA_LOW = 5
MODE_DATA_HIGH = 6
MODE_BREAK_AFTER_DATA_HIGH = 7
MODE_STOP = 8

START_VALUE = [0] + [1] * 128 + [0] * 16
BREAK_VALUE = [0] * 16
END_VALUE = [1] * 145


mode = MODE_START

data_index = 0

while(data_index < len(data_stream)):
    if(data_stream[data_index:data_index+len(START_VALUE)] == START_VALUE):
        #print("Found start at", data_index)
        data_index += len(START_VALUE)

        packet = {}

        packet["config"] = array_to_word(data_stream[data_index:data_index+16])
        data_index += 16

        if(data_stream[data_index:data_index+len(BREAK_VALUE)] != BREAK_VALUE):
            print("missing break, malformed packet")
            continue
        data_index += 16

        packet["data"] = []
        while True:
            vals = [0]*12

            # Record data words 5-0
            for i in range(5,-1,-1):
                vals[i] = array_to_word(data_stream[data_index:data_index+16])
                data_index += 16

            if(data_stream[data_index:data_index+len(BREAK_VALUE)] != BREAK_VALUE):
                print("missing break, malformed packet", data_index, i+len(packet["data"]))
                print(data_stream[data_index:data_index+len(BREAK_VALUE)])
                break 
            data_index += 16

            # Record data words 11-6
            for i in range(11,5,-1):
                vals[i] = array_to_word(data_stream[data_index:data_index+16])
                data_index += 16

            if(data_stream[data_index:data_index+len(BREAK_VALUE)] != BREAK_VALUE):
                print("missing break, malformed packet", data_index, i+len(packet["data"]))
                print(data_stream[data_index:data_index+len(BREAK_VALUE)])
                print(vals)
                break
            data_index += 16

            packet["data"] += vals

            if(data_stream[data_index:data_index+len(END_VALUE)] == END_VALUE):
                print("Found end of packet!"),
                print(len(packet["data"]))
                print("Config: {:016b}".format(packet["config"]))
                for i in range(0,64):
                    print("%2i"%(packet["data"][i])),
                    if(i%16==15):
                        print("")
                print("")
                break
        

    else:
        data_index += 1

print("done")

