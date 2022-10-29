import os, sys, time, struct

floppyPath    = ".\\bin\\floppy.img"
flpSize       = 1474560
tmpPath       = ".\\bin\\tmp.bin"
nasmCommand   = ".\\utils\\nasm -fbin %s -o " + tmpPath
kernelPath    = ".\\bin\\kernel.exe"

params = len(sys.argv)
if (params < 2):
    #print "Usage: \n %s file1.asm [file2.asm] [... fileN.asm]\n"%(sys.argv[0])
    exit(1)

#we have cmd line, open the result file (floppy)
out = open(floppyPath, "wb")
    
#iterate files and compile them and add them to the floppy
for i in range(1, params):
    #print "Compiling %s"%(sys.argv[i])
    os.system(nasmCommand%(sys.argv[i]))
    out.write(open(tmpPath, "rb").read())


# add padding until sector 36 (hardcoded start for kernel.exe)
size = out.tell()
for i in range(0, ((512*36) - size)):
    out.write(b'\0')

if (os.path.getsize(kernelPath) > 216*512): 
    print("\n Warning: Kernel size > 216 sectors!\n")
#write the kernel
out.write(open(kernelPath, "rb").read())


# add padding to the end of floppy
time.sleep(1)  
size = out.tell()
#print "Adding padding from %d to %d ...\n"%(size, flpSize)
for i in range(0, (flpSize - size)):
    sector = (i // 512 + 1) % 255
    out.write(struct.pack("=B", sector))

#cleanup
out.close()
os.remove(tmpPath)