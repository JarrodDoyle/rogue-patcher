# Quick & dirty python script to generate a character encoding file
# for use with wfon.exe.

import sys
if len(sys.argv)<3:
    print("Usage: python wfonchars.py <encoding> <outputfile>");
    print("  e.g. python wfonchars.py windows-1252 win1252.txt");
    sys.exit(1);

codepage = sys.argv[1]
filename = sys.argv[2]

# Write chars 32-255 in the given codepage to the given filename.
chars = ''
for c in range(32,256):
    try:
        u = bytes([c]).decode(codepage)
    except:
        u = ' '
    chars += u
    if c%16==15:
        chars += '\n'
f = open(filename,'wb')
f.write(chars.encode('utf16'))
f.close()
