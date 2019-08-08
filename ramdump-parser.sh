#!/bin/sh

#export PATH=$PATH:

echo ""
echo "Start ramdump parser.."

local_path=$PWD
ramdump=$local_path/
vmlinux=$local_path/vmlinux
out=$local_path/out

gdb=/opt/swi/y22-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-gdb
nm=/opt/swi/y22-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-nm
objdump=/opt/swi/y22-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-objdump

#gdb=/opt/swi/y17-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-gdb
#nm=/opt/swi/y17-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-nm
#objdump=/opt/swi/y17-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-objdump

#gdb=/opt/swi/y27-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-gdb
#nm=/opt/swi/y27-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-nm
#objdump=/opt/swi/y27-ext/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-objdump
# git clone git://codeaurora.org/quic/la/platform/vendor/qcom-opensource/tools
ramparse_dir=/home/jarhu/sw/qualcomm/tools/linux-ramdump-parser-v2/
#ramparse_dir=/home/jarhu/tmp/tools/linux-ramdump-parser-v2
########################################################################################

echo "cd $ramparse_dir"
cd $ramparse_dir
echo ""

echo -e "python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x "
echo ""

# python 2.7.5
#python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x --force-hardware 9640 --32-bit 
python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x  

cd $local_path
echo "out: $out"
echo ""
exit 0
# git clone git://codeaurora.org/quic/la/platform/vendor/qcom-opensource/tools
ramparse_dir=/home/jarhu/sw/qualcomm/tools/linux-ramdump-parser-v2/
#ramparse_dir=/home/jarhu/tmp/tools/linux-ramdump-parser-v2
########################################################################################

echo "cd $ramparse_dir"
cd $ramparse_dir
echo ""

echo -e "python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x "
echo ""

# python 2.7.5
#python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x --force-hardware 9640 --32-bit 
python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x 

cd $local_path
echo "out: $out"
echo ""
exit 0
