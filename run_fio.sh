#!/bin/bash
# Usage: sudo ./run_fio.sh <nvme device path> <size>
# Ex: sudo ./run_fio.sh /dev/nvme0n1 1g

fio_read()
{
	echo -e "\nStarting $2 $5 of bs $3 on $1, with IO Queue Depth $4 \n" >> $fio_log
	fio --name=seqR4k --filename=$1 --rw=$5 --bs=$3 --size=$2 --iodepth=$4 -minimal | gawk -F'[;]' '{print "Total I/O: "$6 "KB", "\nBandwidth: "$7 "KB/s", "\nIOPS: "$8, "\nRuntime: "$9 "ms"}' >> $fio_log
	echo -e "\nCompleted $2 $5 of bs $3 on $1, with IO Queue Depth $4 \n"

}

fio_write()
{
	echo -e "\nStarting $2 $5 of bs $3 on $1, with IO Queue Depth $4 \n" >> $fio_log
	fio --name=seqR4k --filename=$1 --rw=$5 --bs=$3 --size=$2 --iodepth=$4 -minimal --direct=1 | gawk -F'[;]' '{print "Total I/O: "$47 "KB", "\nBandwidth: "$48 "KB/s", "\nIOPS: "$49, "\nRuntime: "$50 "ms"}' >> $fio_log
	echo -e "\nCompleted $2 $5 of bs $3 on $1, with IO Queue Depth $4 \n"

}

echo ===============================================
echo Starting fio on device $1
echo ===============================================
#Do warmup of device

logs=./logdir
fio_log=$logs/fio.log

echo "Logging test results to $fio_log"
echo "Starting fio workloads on device $1" > $fio_log

fio_write $1 $2 64k 1 "write"

fio_write $1 $2 64k 8 "write"

fio_write $1 $2 64k 32 "write"

fio_write $1 $2 128k 1 "write"

fio_write $1 $2 128k 8 "write"

fio_write $1 $2 128k 32 "write"

fio_write $1 $2 64k 1 "randwrite"

fio_write $1 $2 64k 32 "randwrite"

fio_write $1 $2 128k 1 "randwrite"

fio_write $1 $2 128k 32 "randwrite"


fio_read $1 $2 64k 1 "read"

fio_read $1 $2 64k 8 "read"

fio_read $1 $2 64k 32 "read"

fio_read $1 $2 64k 1 "randread"

fio_read $1 $2 64k 32 "randread"

fio_read $1 $2 128k 1 "read"

fio_read $1 $2 128k 8 "read"

fio_read $1 $2 128k 32 "read"

fio_read $1 $2 128k 1 "randread"

fio_read $1 $2 128k 32 "randread"
#fio --name=seqR4k --filename=$1 --rw=read --direct=1 --bs=128k --size=$2 --iodepth=32 -minimal | gawk -F'[;]' '{print "Total I/O: "$6 "KB", "Bandwidth: "$7 "KB/s", "IOPS: "$8, "Runtime: "$9 "ms"}'

