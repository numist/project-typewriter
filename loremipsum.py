#!/opt/local/bin/python2.4

import serial
import time

lorem = """Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
enim ad minim veniam, quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor
in reprehenderit in voluptate velit esse cillum dolore eu fugiat
nulla pariatur. Excepteur sint occaecat cupidatat non proident,
sunt in culpa qui officia deserunt mollit anim id est laborum."""

port = serial.Serial("/dev/tty.usbserial-A7007tDX", 115200)

time.sleep(5)

for c in lorem:
    port.write(c)
    if c == '\n':
        time.sleep(2)
    else:
        time.sleep(0.25)

port.close()
