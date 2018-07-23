#!/bin/bash

fio_read()
{
	echo -e "\nStarting $2 sequential reads of bs $3 on $1, with IO Queue Depth $4 \n"
	fio --name=seqR4k --filename=$1 --rw=read --bs=$3 --size=$2 --iodepth=$4 -minimal | gawk -F'[;]' '{print "Total I/O: "$6 "KB", "\nBandwidth: "$7 "KB/s", "\nIOPS: "$8, "\nRuntime: "$9 "ms"}'

}

fio_write()
{
fio --name=seqR4k --filename=$1 --rw=write --bs=$3 --size=$2 --iodepth=$4 -minimal | gawk -F'[;]' '{print "Total I/O: "$47 "KB", "\nBandwidth: "$48 "KB/s", "\nIOPS: "$49, "\nRuntime: "$50 "ms"}'

}

echo ===============================================
echo Starting fio on device $1
echo ===============================================


fio_read $1 $2 "4k" 1
echo ""
exit 0
#echo -e "\nStarting 4k sequential reads on $1, with IO Queue Depth 8 \n"
fio_read $1 $2 4k 8
echo ""

#echo -e "\nStarting 4k sequential reads on $1, with IO Queue Depth 32 \n"
fio_read $1 $2 4k 32
echo ""

#echo -e "\nStarting 64k sequential reads on $1, with IO Queue Depth 1 \n"
fio_read $1 $2 "64k" 1
echo ""


#echo -e "\nStarting 64k sequential reads on $1, with IO Queue Depth 8 \n"
fio_read $1 $2 64k 8
echo ""

#echo -e "\nStarting 64k sequential reads on $1, with IO Queue Depth 32 \n"
fio_read $1 $2 64k 32
echo ""


#echo -e "\nStarting 128k sequential reads on $1, with IO Queue Depth 1 \n"
fio_read $1 $2 128k 1
echo ""

#echo -e "\nStarting 128k sequential reads on $1, with IO Queue Depth 8 \n"
fio_read $1 $2 128k 8
echo ""

#echo -e "\nStarting 128k sequential reads on $1, with IO Queue Depth 32 \n"
fio_read $1 $2 128k 32 
#fio --name=seqR4k --filename=$1 --rw=read --direct=1 --bs=128k --size=$2 --iodepth=32 -minimal | gawk -F'[;]' '{print "Total I/O: "$6 "KB", "Bandwidth: "$7 "KB/s", "IOPS: "$8, "Runtime: "$9 "ms"}'
echo ""

#echo -e "\nStarting 128k sequential writes on $1, with IO Queue Depth 1 \n"
fio_write $1 $2 128k 1
echo ""

#echo -e "\nStarting 128k sequential writes on $1, with IO Queue Depth 8 \n"
fio_write $1 $2 128k 8
echo ""

#echo -e "\nStarting 128k sequential writes on $1, with IO Queue Depth 32 \n"
fio_writerun $1 $2 128k 8
echo ""

#echo -e "\nStarting 4k sequential writes on $1, with IO Queue Depth 1 \n"
fio_write $1 $2 4k 1
echo ""

