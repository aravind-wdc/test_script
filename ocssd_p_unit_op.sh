#!/bin/bash 

run_operation()
{
	echo -e "\n Issuing $1 command on device $4, on pugrp $2, on punit $3 with $5 chunks"
	for (( i=0; i<$5; i++ ))
	do
		chunk_saddr=`sudo ./nvm_addr s20_to_gen $4 $2 $3 $i 0 | gawk '/val:/ {print $3}' | gawk -F '[,]' '{print $1}'`
		sudo ./nvm_vblk $1 $4 $chunk_saddr >> ./logs/ocssd_sanity_$1$2$3.log
		ret_val=$?
		if [ $ret_val -ne 0 ];
		then
			echo "Failure: $1 command failed on address $chunk_saddr"
		fi
	done
}
#$1=op command, $2=pugrp num, $3=punit num, $4=device path, $5=num of chunk per punit
run_operation $1 $2 $3 $4 $5
