#!/bin/bash
# Usage: sudo ./run_fio.sh <nvme device path> <size>
# Ex: sudo ./run_fio.sh /dev/nvme0n1 1g

fio_read()
{
	echo -e "\nStarting $2 $5 of bs $3 on $1, with IO Queue Depth $4 \n"
	fio --name=seqR4k --filename=$1 --rw=$5 --bs=$3 --size=$2 --iodepth=$4 -minimal | gawk -F'[;]' '{print "Total I/O: "$6 "KB", "\nBandwidth: "$7 "KB/s", "\nIOPS: "$8, "\nRuntime: "$9 "ms"}'
	echo ""

}

fio_write()
{
	echo -e "\nStarting $2 $5 of bs $3 on $1, with IO Queue Depth $4 \n"
	fio --name=seqR4k --filename=$1 --rw=$5 --bs=$3 --size=$2 --iodepth=$4 -minimal | gawk -F'[;]' '{print "Total I/O: "$47 "KB", "\nBandwidth: "$48 "KB/s", "\nIOPS: "$49, "\nRuntime: "$50 "ms"}'
	echo ""

}

echo ===============================================
echo Starting fio on device $1
echo ===============================================
#Do warmup of device


fio_read $1 $2 4k 1 "read"
#echo -e "\nStarting 4k sequential reads on $1, with IO Queue Depth 8 \n"
fio_read $1 $2 4k 8 "read"

#echo -e "\nStarting 4k sequential reads on $1, with IO Queue Depth 32 \n"
fio_read $1 $2 4k 32 "read"

#echo -e "\nStarting 64k sequential reads on $1, with IO Queue Depth 1 \n"
fio_read $1 $2 64k 1 "read"


#echo -e "\nStarting 64k sequential reads on $1, with IO Queue Depth 8 \n"
fio_read $1 $2 64k 8 "read"


#echo -e "\nStarting 128k sequential reads on $1, with IO Queue Depth 1 \n"
fio_read $1 $2 128k 1 "read"

#echo -e "\nStarting 128k sequential reads on $1, with IO Queue Depth 8 \n"
fio_read $1 $2 128k 8 "read"

#echo -e "\nStarting 128k sequential reads on $1, with IO Queue Depth 32 \n"
fio_read $1 $2 128k 32 "read"
#fio --name=seqR4k --filename=$1 --rw=read --direct=1 --bs=128k --size=$2 --iodepth=32 -minimal | gawk -F'[;]' '{print "Total I/O: "$6 "KB", "Bandwidth: "$7 "KB/s", "IOPS: "$8, "Runtime: "$9 "ms"}'

#echo -e "\nStarting 128k sequential writes on $1, with IO Queue Depth 1 \n"
fio_write $1 $2 128k 1 "write"

#echo -e "\nStarting 128k sequential writes on $1, with IO Queue Depth 8 \n"
fio_write $1 $2 128k 8 "write"

#echo -e "\nStarting 128k sequential writes on $1, with IO Queue Depth 32 \n"
fio_write $1 $2 128k 32 "write"

#echo -e "\nStarting 4k sequential writes on $1, with IO Queue Depth 1 \n"
fio_write $1 $2 4k 1 "write"

fio_write $1 $2 4k 8 "write"

fio_write $1 $2 4k 32 "write"


fio_write $1 $2 4k 1 "randwrite"


fio_write $1 $2 4k 32 "randwrite"

fio_write $1 $2 128k 1 "randwrite"

fio_write $1 $2 128k 32 "randwrite"
