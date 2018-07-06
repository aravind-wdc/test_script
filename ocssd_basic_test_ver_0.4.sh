#!/bin/bash 


usage()
{
	echo Usage: Pass the ocssd nvme device path, ex: /dev/nvme0n1
	echo Ensure liblightnvm is installed.
	echo Run as sudo ocssd_basic_test.sh

}

# Run a command to ensure command succeeds
run_command()
{
	echo "Running command $1"
	$1 >> ./tmp.log
	ret_val=$?
	#if $1
	if [ $ret_val -eq 0 ];
	then
		echo -e "\t\nSuccess\n"
	else
		# Want to exit the test ?
		echo Command failed with error code $?
        echo Exiting
        exit 1
	fi
}

# First arg is dev path, 2 nd arg is address in 0xaddr format
nvm_vblk_addr_erase()
{
#    echo Erasing block $2 on device $1
	sudo ./nvm_vblk erase $1 $2 >> tmp.log
	ret_val=$?
	if [ $ret_val -ne 0 ];
	then
		echo Failure: Erase command failed on address 0x$2
	fi
}

# First arg is dev path, 2 nd arg is address in 0xaddr format
nvm_vblk_addr_write()
{
    echo Writing block $2 on device $1
	sudo ./nvm_vblk write $1 $2 >> tmp.log
	ret_val=$?
	if [ $ret_val -ne 0 ];
	then
		echo "Failure: Write command failed on address 0x$2"
	fi
}

# First arg is dev path, 2 nd arg is address in 0xaddr format
nvm_vblk_addr_read()
{
#    echo Reading block $2 on device $1
	sudo ./nvm_vblk read $1 $2 >> tmp.log
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
    sudo ./nvm_cmd rprt_all $mydev_path | grep slba | while read -r line ; do
        #echo -e "Processing \n $line"
        slba=`echo "$line" | gawk '/slba:/ {print $4}' | gawk -F '[,]' '{print $1}'`
        wp=`echo "$line" | gawk '/wp:/ {print $8}' | gawk -F '[,]' '{print $1}'`
        cs=`echo "$line" | gawk '/cs:/ {print $10}' | gawk -F '[,]' '{print $1}'`
        if [ $1 != $cs -o $2 -ne $wp ];
        then
            echo "Failure: Unexpected write pointer or chunkstate found, exiting."
            echo "Slba = $slba, Expected CS=$1, Reported CS=$cs Expected WP:$2, Reported WP=$wp "
        fi
    done
    echo -e "\nVerified all chunk state to be $1 and write pointers to be $2 \n"


}

#Erase all the chunks in SSD
nvm_erase_and_verify_all_chunks()
{
    echo -e "\nStarting erase of all chunks in the device: $mydev_path  "
    echo -e "pugrp=\t\t\t$dev_npugrp, \nnpunit=\t\t\t$dev_npunit, \nnchunks=\t\t$dev_nchunk, \nnsectors=\t\t$dev_nsectr"
    echo -e "bytespersector=\t\t$dev_nbytespersectr, \noob=\t\t\t$dev_nbytes_oob, \ntotal bytes=\t\t$dev_total_bytes, \ntotal mbytes=\t\t$dev_total_mbytes"

    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            do
                # Generate chunk start address
                chunk_saddr=`sudo ./nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                #echo  "Chunk start address: $chunk_saddr"
                #run_command "sudo ./nvm_vblk erase $mydev_path $chunk_saddr"
                nvm_vblk_addr_erase $mydev_path $chunk_saddr

            done
        done
    done
    nvm_verify_all_cs_wp 0x01 0
    echo -e "\nErase and verify of all chunks complete. \n"
}

create_4k_file()
{
    for (( x=0; x<1024; x++ ))
    do
        echo "xby" >> ./4k_data
    done
}

nvm_write_read_all_chunks()
{
    echo -e "\nStarting writes and reads to all the chunks in device $mydev_path \n"
    #mydev_path=$1
    #dev_npugrp=`sudo ./nvm_dev info $mydev_path | gawk '/npugrp:/ {print $2}'`
    #dev_npunit=`sudo ./nvm_dev info $mydev_path | gawk '/npunit:/ {print $2}'`
    #dev_nchunk=`sudo ./nvm_dev info $mydev_path | gawk '/nchunk:/ {print $2}'`
    #dev_nsectr=`sudo ./nvm_dev info $mydev_path | gawk '/nsectr:/ {print $2}'`
    #dev_nbytespersectr=`sudo ./nvm_dev info $mydev_path | gawk '/nbytes:/ {print $2}'`
    #dev_nbytes_oob=`sudo ./nvm_dev info $mydev_path | gawk '/nbytes_oob:/ {print $2}'`
    #dev_total_bytes=`sudo ./nvm_dev info $mydev_path | gawk '/tbytes:/ {print $2}'`
    #dev_total_mbytes=`sudo ./nvm_dev info $mydev_path | gawk '/tmbytes:/ {print $2}'`
    #echo Device geometry: 
    #echo -e "pugrp=\t\t\t$dev_npugrp, \nnpunit=\t\t\t$dev_npunit, \nnchunks=\t\t$dev_nchunk, \nnsectors=\t\t$dev_nsectr"
    #echo -e "bytespersector=\t\t$dev_nbytespersectr, \noob=\t\t\t$dev_nbytes_oob, \ntotal bytes=\t\t$dev_total_bytes, \ntotal mbytes=\t\t$dev_total_mbytes"


    for (( i=0; i<$dev_npugrp; i++ ))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            for (( k=0; k<$dev_nchunk; k++ ))
            #for (( k=0; k<5; k++ ))
            do
                # Generate chunk start address
                chunk_saddr=`sudo ./nvm_addr s20_to_gen $mydev_path $i $j $k 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                #echo  "Chunk start address: $chunk_saddr"
                #run_command "sudo ./nvm_vblk erase $mydev_path $chunk_saddr"
                #nvm_vblk_addr_erase $mydev_path $chunk_saddr
                nvm_vblk_addr_write $mydev_path $chunk_saddr
                nvm_vblk_addr_read $mydev_path $chunk_saddr

                # Sector level ops
                #for (( l=0; l<$dev_nsectr; l++))
                #do
                    #sudo ./nvm_addr s20_to_gen $mydev_path $i $j $k $l				
                    #echo in loop i=$i, j=$j, k=$k, l=$l
                #done
            done
            #TODO Check chunk state here.
        done
    done
    nvm_verify_all_cs_wp 0x02 4096
    echo -e "\nWrite and read on all chunks complete \n"

}


nvm_erase_write_read_all_sectors()
{

    echo -e "\nStarting writes and reads on all sectors \n"
    #mydev_path=$1
    #dev_npugrp=`sudo ./nvm_dev info $mydev_path | gawk '/npugrp:/ {print $2}'`
    #dev_npunit=`sudo ./nvm_dev info $mydev_path | gawk '/npunit:/ {print $2}'`
    #dev_nchunk=`sudo ./nvm_dev info $mydev_path | gawk '/nchunk:/ {print $2}'`
    #dev_nsectr=`sudo ./nvm_dev info $mydev_path | gawk '/nsectr:/ {print $2}'`
    #dev_nbytespersectr=`sudo ./nvm_dev info $mydev_path | gawk '/nbytes:/ {print $2}'`
    #dev_nbytes_oob=`sudo ./nvm_dev info $mydev_path | gawk '/nbytes_oob:/ {print $2}'`
    #dev_total_bytes=`sudo ./nvm_dev info $mydev_path | gawk '/tbytes:/ {print $2}'`
    #dev_total_mbytes=`sudo ./nvm_dev info $mydev_path | gawk '/tmbytes:/ {print $2}'`
    #echo Device geometry: 
    #echo -e "pugrp=\t\t\t$dev_npugrp, \nnpunit=\t\t\t$dev_npunit, \nnchunks=\t\t$dev_nchunk, \nnsectors=\t\t$dev_nsectr"
    #echo -e "bytespersector=\t\t$dev_nbytespersectr, \noob=\t\t\t$dev_nbytes_oob, \ntotal bytes=\t\t$dev_total_bytes, \ntotal mbytes=\t\t$dev_total_mbytes"
    local count=1

    for (( i=0; i<$dev_npugrp; i++))
    do
        for (( j=0; j<$dev_npunit; j++ ))
        do
            #for (( k=0; k<$dev_nchunk; k++ ))
            for (( k=0; k<5; k++ ))
            do
                #echo  "Chunk start address: $chunk_saddr"
                # Sector level ops
                for (( l=0; l<$dev_nsectr; l++))
                do
                    # Generate sector start address
                    sector_saddr=`sudo ./nvm_addr s20_to_gen $mydev_path $i $j $k $l | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
                    echo "i = $i, j = $j, k=$k, l=$l"

                    local s_addr=$s_addr" $sector_saddr"
                    #echo -e "sector address = $s_addr count = $count"
                    if [ $count -eq 4 ];
                    then
                        run_command "sudo ./nvm_cmd write $mydev_path $s_addr"
                        count=0
                        s_addr=""
                    fi
                    #$count=$count + 1
                    ((count++))


                    #run_command "sudo ./nvm_cmd write $mydev_path $chunk_saddr"

                    #echo in loop i=$i, j=$j, k=$k, l=$l
                done
            done
        done
    done


    echo -e "\n Writes and reads on all sectors completed. \n"
}
get_dev_geo_var()
{

    dev_npugrp=`sudo ./nvm_dev info $mydev_path | gawk '/npugrp:/ {print $2}'`
    dev_npunit=`sudo ./nvm_dev info $mydev_path | gawk '/npunit:/ {print $2}'`
    dev_nchunk=`sudo ./nvm_dev info $mydev_path | gawk '/nchunk:/ {print $2}'`
    dev_nsectr=`sudo ./nvm_dev info $mydev_path | gawk '/nsectr:/ {print $2}'`
    dev_nbytespersectr=`sudo ./nvm_dev info $mydev_path | gawk '/nbytes:/ {print $2}'`
    dev_nbytes_oob=`sudo ./nvm_dev info $mydev_path | gawk '/nbytes_oob:/ {print $2}'`
    dev_total_bytes=`sudo ./nvm_dev info $mydev_path | gawk '/tbytes:/ {print $2}'`
    dev_total_mbytes=`sudo ./nvm_dev info $mydev_path | gawk '/tmbytes:/ {print $2}'`
    echo Device geometry: 
    echo -e "pugrp=\t\t\t$dev_npugrp, \nnpunit=\t\t\t$dev_npunit, \nnchunks=\t\t$dev_nchunk, \nnsectors=\t\t$dev_nsectr"
    echo -e "bytespersector=\t\t$dev_nbytespersectr, \noob=\t\t\t$dev_nbytes_oob, \ntotal bytes=\t\t$dev_total_bytes, \ntotal mbytes=\t\t$dev_total_mbytes"
}

echo =======================================================================================================================================
echo "Starting unit tests for ocssd on device $1. This test deletes all data on the disk, stop now, if you are not sure(Ctrl-c)."
echo =======================================================================================================================================
sleep 2

if [ $# -ne 1 ]; then
	usage
fi
echo "Creating a file of size 4K"

create_4k_file

mydev_path=$1

# Do git clone of liblightnvm master and compile it and use the binaries.

#echo Device path = $mydev_path
#mkdir -p git_tmp
#cd git_tmp
#git clone https://github.com/OpenChannelSSD/liblightnvm.git
#cd liblightnvm
#make configure
#make
#cd build/cli
#run_command "sudo ./nvm_dev info $mydev_path"
#run_command "sudo ./nvm_cmd idfy $mydev_path"



echo "Running tests on device $mydev_path"

run_command "sudo ./nvm_cmd idfy $mydev_path"
#run_command "sudo ./nvm_dev attr $mydev_path"
run_command "sudo ./nvm_dev info $mydev_path"
#run_command "sudo ./nvm_dev geo $mydev_path"
#run_command "sudo ./nvm_dev ppaf $mydev_path"

#dev_attr=`sudo ./nvm_dev attr $mydev_path`

#echo Stored attributes in dev_attr = $dev_attr
#dev_geo=`sudo ./nvm_dev geo $mydev_path`
dev_info=`sudo ./nvm_dev info $mydev_path`

#echo Stored attributes in dev_geo = $dev_geo
get_dev_geo_var
nvm_erase_and_verify_all_chunks
#nvm_write_read_all_chunks
nvm_erase_write_read_all_sectors

# Delete the git repository.
# cd ../../../..
# rm -rf ./git_tmp
