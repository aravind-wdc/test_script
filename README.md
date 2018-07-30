# test_script

This is a set of tests specifically written to run on Openchannel SSDs. It is assumed that it is run on OCSSD compliant SSD. 
Dependencies:
It needs access to liblightnvm library, which it clones from the github and compiles it.
It needs the fio from the following repository, which is not yet merged in the master fio tree. It supports Zoned block devices.
https://github.com/bvanassche/fio

It expects the "nvme" binary is available in the system. (sudo apt-get install nvme-cli)

Usage:
./ocssd_test_suite.sh /dev/nvme0n1 

./run_fio /dev/nvme0n1 1g
