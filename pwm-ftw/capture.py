#!/usr/bin/python3

# Trigger a capture from an already enabled Saleae logic instance
#
# To install:
# sudo apt install python3-pip
# sudo pip3 install saleae
import saleae

sal = saleae.Saleae()
sal._cmd('CAPTURE')
