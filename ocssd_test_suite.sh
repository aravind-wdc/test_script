#!/bin/bash 


usage()
{
	echo "Usage: Pass the ocssd nvme device path and device type. ex: ./ocssd_test_suite.sh /dev/nvme0n1 qssd "
	echo "Ensure liblightnvm is installed."
	echo "Run as sudo ocssd_basic_test.sh <dev_path> <qssd/pssd> "
	echo "qssd is qemu emulated ocssd, pssd is physical Ocssd"
}

# Run a command to ensure command succeeds
run_command()
{
	echo "Running command $1" >> $logs/ocssd_sanity.log
	$1 >> $logs/ocssd_sanity.log
	ret_val=$?
	#if $1
	if [ $ret_val -eq 0 ];
	then
		echo -e "\t\nSuccess\n" >> $logs/ocssd_sanity.log
	else
		# Want to exit the test ?
		echo Command $1 failed with error code $?
        echo Exiting
        exit 1
	fi
}

# First arg is dev path, 2 nd arg is address in 0xaddr format
nvm_vblk_addr_erase()
{
    echo Erasing block $2 on device $1 >> $logs/ocssd_sanity.log
	sudo $llnvm_path_be_lba/nvm_vblk erase $1 $2 >> $logs/ocssd_sanity.log
	ret_val=$?
	if [ $ret_val -ne 0 ];
	then
		echo Failure: Erase command failed on address 0x$2
	fi
}

# First arg is dev path, 2 nd arg is address in 0xaddr format
nvm_vblk_addr_write()
{
    echo Writing block $2 on device $1 >> $logs/ocssd_sanity.log
	sudo $llnvm_path_be_lba/nvm_vblk write $1 $2 >> $logs/ocssd_sanity.log
	ret_val=$?
	if [ $ret_val -ne 0 ];
	then
		echo "Failure: Write command failed on address 0x$2"
	fi
}

# First arg is dev path, 2 nd arg is address in 0xaddr format
nvm_vblk_addr_read()
{
    echo Reading block $2 on device $1 >> $logs/ocssd_sanity.log
	sudo $llnvm_path_be_lba/nvm_vblk read $1 $2 >> $logs/ocssd_sanity.log
	ret_val=$?
	if [ $ret_val -ne 0 ];
	then
		echo "Failure: Read command failed on address 0x$2"
	fi
}

# first arg is expected val of chunk state, 2nd arg is expected value of wp
nvm_verify_all_cs_wp()
{
    echo -e "\nVerifying all chunk state to be $1 and write pointers to be $2 \n"
    sudo $llnvm_path_be_lba/nvm_cmd rprt_all $mydev_path | grep slba | while read -r line ; do
        #echo -e "Processing \n $line"
        slba=`echo "$line" | gawk '/slba:/ {print $4}' | gawk -F '[,]' '{print $1}'`
        wp=`echo "$line" | gawk '/wp:/ {print $8}' | gawk -F '[,]' '{print $1}'`
        cs=`echo "$line" | gawk '/cs:/ {print $10}' | gawk -F '[,]' '{print $1}'`
        if [ $1 != $cs -o $2 -ne $wp ];
        then
            echo "Slba = $slba, Expected CS=$1, Reported CS=$cs Expected WP:$2, Reported WP=$wp "
            echo "Failure: Unexpected write pointer or chunkstate found, exiting."
			exit 1
        fi
    done
    echo -e "\nVerified all chunk state to be $1 and write pointers to be $2 \n"
}
#Erase using nvme-dsm command
nvm_dsm_erase_and_verify_all_chunks()
{
    echo -e "\nStarting erase of all chunks in the device: $mydev_path  \n"
#    echo -e "pugrp=\t\t\t$dev_npugrp, \nnpunit=\t\t\t$dev_npunit, \nnchunks=\t\t$dev_nchunk, \nnsectors=\t\t$dev_nsectr"
#    echo -e "bytespersector=\t\t$dev_nbytespersectr, \noob=\t\t\t$dev_nbytes_oob, \ntotal bytes=\t\t$dev_total_bytes, \ntotal mbytes=\t\t$dev_total_mbytes"

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            do
                # Generate chunk start address
                chunk_saddr=`sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                #echo  "Chunk start address: $chunk_saddr"
                dev_addr=`sudo $llnvm_path_be_lba/nvm_addr gen2dev $mydev_path $chunk_saddr | gawk '{print $4}'`
                #echo  "lba start address: $dev_addr"
                run_command "sudo nvme dsm $mydev_path -n 1 --slbs $dev_addr -c 0 -d 1"
            done
        done
    done
    nvm_verify_all_cs_wp 0x01 0
    echo -e "\nErase and verify of all chunks complete. \n"

}

#Erase all the chunks in SSD
nvm_erase_and_verify_all_chunks()
{
    echo -e "\nStarting erase of all chunks in the device: $mydev_path  \n"
    echo -e "pugrp=\t\t\t$dev_npugrp, \nnpunit=\t\t\t$dev_npunit, \nnchunks=\t\t$dev_nchunk, \nnsectors=\t\t$dev_nsectr"
    echo -e "bytespersector=\t\t$dev_nbytespersectr, \noob=\t\t\t$dev_nbytes_oob, \ntotal bytes=\t\t$dev_total_bytes, \ntotal mbytes=\t\t$dev_total_mbytes"

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            do
                # Generate chunk start address
                chunk_saddr=`sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                #echo  "Chunk start address: $chunk_saddr"
                #run_command "sudo $llnvm_path_be_lba/nvm_vblk erase $mydev_path $chunk_saddr"
                nvm_vblk_addr_erase $mydev_path $chunk_saddr

            done
        done
    done
    nvm_verify_all_cs_wp 0x01 0
    echo -e "\nErase and verify of all chunks complete. \n"
}

create_4k_file()
{
    ##for (( x=0; x<1024; x++ ))
	if [ ! -f ./4K_data ]; then
		for (( x=0; x<128; x++ ))
		do
			##echo "xby" >> ./4k_data
			echo "This is a 31 char test string!." >> ./4K_data
		done
	fi
}
create_16M_file()
{
	if [ ! -f ./16M_data ]; then
		for (( x=0; x<4096; x++ ))
		do
			#echo "This is a 31 char test string!." >> ./4k_data
			cat ./4K_data >> ./16M_data
		done
	fi
}

#Data Validation. Do writes from the input file and verify the data after read.
nvm_data_validation_all_chunks()
{
	echo -e "\nStarting data validation tests on all chunks"

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            #for (( k=0; k<5; k++ ))
            do
                # Generate chunk start address
                chunk_saddr=`sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
				run_command "sudo $llnvm_path_be_lba/nvm_vblk write $mydev_path $chunk_saddr -i ./16M_data"
				run_command "sudo $llnvm_path_be_lba/nvm_vblk read $mydev_path $chunk_saddr -o ./read_output"
				diff ./16M_data ./read_output 
				data_error=$?
				if [ $data_error -eq 1 ]; then
					echo -e "\nError: Unexpected data read from the disk at chunk addr: $chunk_saddr"
					exit 1
				fi
				rm -rf ./read_output
			done
		done
	done

	echo -e "\nCompleted validating data across the disk.\n"

}

nvm_write_verify_all_chunks()
{
    echo -e "\nStarting writes to all the chunks in device $mydev_path \n"

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            #for (( k=0; k<5; k++ ))
            do
                # Generate chunk start address
                chunk_saddr=`sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                #echo  "Chunk start address: $chunk_saddr"
                #run_command "sudo $llnvm_path_be_lba/nvm_vblk erase $mydev_path $chunk_saddr"
                nvm_vblk_addr_write $mydev_path $chunk_saddr

                # Sector level ops
                #for (( l=0; l<$dev_nsectr; l++))
                #do
                    #sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k $l
                    #echo in loop i=$i, j=$j, k=$k, l=$l
                #done
            done
        done
    done
    echo -e "\nWrites on all chunks completed. \nVerify CS=CLOSED(0x02) and WP=4096. \n"
    nvm_verify_all_cs_wp 0x02 4096
}

nvm_read_all_chunks()
{
    echo -e "\nStarting reads to all the chunks in device $mydev_path \n"

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            #for (( k=0; k<5; k++ ))
            do
                # Generate chunk start address
                chunk_saddr=`sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                #echo  "Chunk start address: $chunk_saddr"
                #run_command "sudo ./nvm_vblk erase $mydev_path $chunk_saddr"
                nvm_vblk_addr_read $mydev_path $chunk_saddr
                # Sector level ops
                #for (( l=0; l<$dev_nsectr; l++))
                #do
                    #sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k $l
                    #echo in loop i=$i, j=$j, k=$k, l=$l
                #done
            done
        done
    done
    echo -e "\nReads on all chunks completed."
}
nvm_partial_chunk_write_and_verify_cs_wp()
{
    echo -e "\nDoing partial writes to all chunks and verify cs and wp. \n "
    # Do partial writes to all chunks in SSD (write to first sectors of all chunks). 
    # verify that cs is free before writing and open after writing 
    local count=0

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            do
                #echo  "Chunk start address: $chunk_saddr"
                # Generate sector start address
                sector_saddr=`sudo $llnvm_path_be_ioctl/nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                local s_addr=$s_addr" $sector_saddr"
                ((count++))
                #echo -e "sector address = $s_addr count = $count"
                if [ $count -eq 32 ];
                then
                    run_command "sudo $llnvm_path_be_ioctl/nvm_cmd write $mydev_path $s_addr"
                    count=0
                    #run_command "sudo $llnvm_path/nvm_cmd read $mydev_path $s_addr"
                    s_addr=""
                fi
                #$count=$count + 1


                #run_command "sudo $llnvm_path/nvm_cmd write $mydev_path $chunk_saddr"

                #echo in loop i=$i, j=$j, k=$k, l=$l
            done
            
            if [ $count -gt 0 -a $count -lt 32 ];
            then
                run_command "sudo $llnvm_path_be_ioctl/nvm_cmd write $mydev_path $s_addr"
                count=0
                s_addr=""
            fi

        done
    done
    echo -e "\nPartial Writes on all sectors completed. \nVerify CS=OPEN(0x04) and WP=1. \n"
    nvm_verify_all_cs_wp 0x04 1  

}

nvm_write_read_all_sectors()
{

    echo -e "\nStarting writes and reads on all sectors \n"
    local count=0

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            #for (( k=0; k<$dev_nchunk; k++ ))
            for (( k=0; k<$dev_nchunk; k++ ))
            do
                #echo  "Chunk start address: $chunk_saddr"
                # Sector level ops
                for (( l=0; l<$dev_nsectr; l++))
                do
                    # Generate sector start address
                    sector_saddr=`sudo $llnvm_path_be_lba/nvm_addr s20_to_gen $mydev_path $i $j $k $l | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                    local s_addr=$s_addr" $sector_saddr"
                    ((count++))
                    #echo -e "sector address = $s_addr count = $count"
                    if [ $count -eq 32 ]; #TODO: Ensure nsector is multiple of 8
                    then
                        run_command "sudo $llnvm_path_be_ioctl/nvm_cmd write $mydev_path $s_addr"
                        count=0
                        run_command "sudo $llnvm_path_be_ioctl/nvm_cmd read $mydev_path $s_addr"
                        s_addr=""
                    fi
                    #run_command "sudo ./nvm_cmd write $mydev_path $chunk_saddr"
                    #echo in loop i=$i, j=$j, k=$k, l=$l
                done
                # Do the writes/reads to the remaining sectors (nsects%32)
                if [ $count -gt 0 -a $count -lt 32 ];
                then
                    run_command "sudo $llnvm_path_be_ioctl/nvm_cmd write $mydev_path $s_addr"
                    count=0
                    run_command "sudo $llnvm_path_be_ioctl/nvm_cmd read $mydev_path $s_addr"
                    s_addr=""
                fi
            done
        done
    done
    echo -e "\n Writes and reads on all sectors completed. Verify CS=CLOSED(0x02) and WP=4096. \n"
    nvm_verify_all_cs_wp 0x02 4096
}

#Issue erases, writes, reads to different pugrps and punits. 
#Ex: If a ssd had 2 pugrps and each pugrp had 4 punits, then 8 process will start issuing cmds in parallel on the 8 punits.
# Arg 1 is the command, i.e. erase or write or read
nvm_issue_parallel_operations()
{
	echo -e "\nStarting parallel $1 operations on $mydev_path" 
	for (( i=0; i<$dev_npugrp; i++ ))
	do
		for (( j=0; j<$dev_npunit; j++ ))
		do
			date >> $logs/ocssd_sanity.log
			echo "Running cmd sudo ./ocssd_p_unit_op.sh $1 $i $j $mydev_path $dev_nchunk $logs $llnvm_path &"
			sudo ./ocssd_p_unit_op.sh $1 $i $j $mydev_path $dev_nchunk $logs $llnvm_path  &
		done
	done
	wait

	echo -e "\nCompleted parallel $1 operations on $mydev_path"
}


nvm_line_erase_all_chunks()
{
    echo -e "\nStarting line erase of chunks"
    let "npgrp = $dev_npugrp - 1"
    let "npunit = $dev_npunit - 1"
    for (( i=0; i<$dev_nchunk; i++))
    do
        run_command "sudo $llnvm_path_be_lba/nvm_vblk line_erase $mydev_path 0 $npgrp 0 $npunit $i"
    done
    echo -e "\nErased $i lines across $dev_npugrp parallel groups and $dev_npunit parallel units."
    echo -e "\nVerify CS=Free (0x01), WP=0."
    nvm_verify_all_cs_wp 0x01 0
}

nvm_line_write_all_chunks()
{
    echo -e "\nStarting line write of chunks"
    let "npgrp = $dev_npugrp - 1"
    let "npunit = $dev_npunit - 1"
    for (( i=0; i<$dev_nchunk; i++))
    do
        run_command "sudo $llnvm_path_be_lba/nvm_vblk line_write $mydev_path 0 $npgrp 0 $npunit $i"
    done
    echo -e "\nWritten $i lines across $dev_npugrp parallel groups and $dev_npunit parallel units."
    echo -e "\nVerify CS=CLOSED(0x02) and WP=4096. \n"
    nvm_verify_all_cs_wp 0x02 4096
}


nvm_line_read_all_chunks()
{
    echo -e "\nStarting line read of chunks"
    let "npgrp = $dev_npugrp - 1"
    let "npunit = $dev_npunit - 1"
    for (( i=0; i<$dev_nchunk; i++))
    do
        run_command "sudo $llnvm_path_be_lba/nvm_vblk line_read $mydev_path 0 $npgrp 0 $npunit $i"
    done
    echo -e "\nRead $i lines across $dev_npugrp parallel groups and $dev_npunit parallel units."
    #TODO: Data integrity check.
}
get_liblightnvm()
{
    echo "Doing git clone of liblightnvm master and compile it and use the binaries."
    if [ ! -d ./liblightnvm ]; then
        run_command "sudo git clone -b fix_lba https://github.com/OpenChannelSSD/liblightnvm.git"
    fi
    echo "Found existing liblightnvm !!!"
    cd liblightnvm
    if [ "$1" == "pssd" ]; then
		if [ ! -f ./patch_applied ]; then
        	echo "Applying patch for pssd"
        	sudo git apply ../ftl_patch.patch
			sudo touch ./patch_applied
			run_command "make configure"
			run_command "make"
		fi
    elif [ "$1" == "qssd" ]; then
		if [ -f ./patch_applied ]; then
			echo "Removing the patch"
			sudo git apply -R ../ftl_patch.patch
			sudo rm -f ./patch_applied
			run_command "make configure"
			run_command "make"
		fi
    fi
    #cd build/cli
    #mkdir -p logs
    cd ..
}

get_dev_geo()
{

    dev_npugrp=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/npugrp:/ {print $2}'`
    dev_npunit=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/npunit:/ {print $2}'`
    dev_nchunk=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/nchunk:/ {print $2}'`
    dev_nsectr=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/nsectr:/ {print $2}'`
    dev_nbytespersectr=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/nbytes:/ {print $2}'`
    dev_nbytes_oob=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/nbytes_oob:/ {print $2}'`
    dev_total_bytes=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/tbytes:/ {print $2}'`
    dev_total_mbytes=`sudo $llnvm_path_be_lba/nvm_dev info $mydev_path | gawk '/tmbytes:/ {print $2}'`
    echo Device geometry: 
    echo -e "pugrp=\t\t\t$dev_npugrp, \nnpunit=\t\t\t$dev_npunit, \nnchunks=\t\t$dev_nchunk, \nnsectors=\t\t$dev_nsectr"
    echo -e "bytespersector=\t\t$dev_nbytespersectr, \noob=\t\t\t$dev_nbytes_oob, \ntotal bytes=\t\t$dev_total_bytes, \ntotal mbytes=\t\t$dev_total_mbytes"
}

echo =======================================================================================================================================
echo "Starting unit tests for ocssd on device $1. This test deletes all data on the disk, stop now, if you are not sure(Ctrl-c)."
echo =======================================================================================================================================
sleep 5 

if [ $# -ne 2 ]; then
	usage
	exit 1
fi
mkdir -p logdir
logs=$PWD/logdir
#echo "logdir = $logs"

if [ ! -b $1 ]; then
	echo "Device $1 not found, Exiting"
	exit 1
fi

echo "Creating a file of size 4K and 16M" > $logs/ocssd_sanity.log
create_4k_file
create_16M_file

get_liblightnvm $2

llnvm_path_be_lba="NVM_CLI_BE_ID=4 ./liblightnvm/build/cli"
llnvm_path_be_ioctl="NVM_CLI_BE_ID=1 ./liblightnvm/build/cli"
llnvm_path="./liblightnvm/build/cli"
mydev_path=$1

#echo Device path = $mydev_path

#run_command "sudo ./nvm_dev info $mydev_path"
#run_command "sudo ./nvm_cmd idfy $mydev_path"

#echo "llnvm_path = $llnvm_path"
run_command "sudo $llnvm_path_be_ioctl/nvm_cmd idfy $mydev_path"
echo "Running tests on device $mydev_path"
run_command "sudo $llnvm_path_be_lba/nvm_cmd idfy $mydev_path"
#run_command "sudo $llnvm_path/nvm_dev attr $mydev_path"
run_command "sudo $llnvm_path_be_lba/nvm_dev info $mydev_path"

echo "Test 1"
get_dev_geo
echo "Test 2"
nvm_dsm_erase_and_verify_all_chunks
###nvm_erase_and_verify_all_chunks
echo "Test 3"
nvm_write_verify_all_chunks
echo "Test 4"
nvm_read_all_chunks
echo "Test 5"
nvm_dsm_erase_and_verify_all_chunks
###nvm_line_erase_all_chunks #TODO: uncomment once the fw supports the erase command
nvm_line_write_all_chunks
echo "Test 6"
nvm_line_read_all_chunks
echo "Test 7"
nvm_dsm_erase_and_verify_all_chunks
nvm_partial_chunk_write_and_verify_cs_wp
echo "Test 8"
###nvm_issue_parallel_operations erase
###nvm_verify_all_cs_wp 0x01 0
echo "Test 9"
nvm_dsm_erase_and_verify_all_chunks
nvm_issue_parallel_operations "write"
nvm_verify_all_cs_wp 0x02 4096
echo "Test 10"
nvm_issue_parallel_operations "read"
echo "Test 11"
nvm_dsm_erase_and_verify_all_chunks
nvm_data_validation_all_chunks
### Sector level operations take a lot of time, uncomment below 2 lines to do sector ops.
###echo "Test 12"
###nvm_erase_and_verify_all_chunks
###nvm_dsm_erase_and_verify_all_chunks
###nvm_write_read_all_sectors


# Delete the git repository. Uncomment this when it goes to the smoke env so that latest liblightnvm can be used everytime
#cd ../../..
#rm -rf ./liblightnvm
