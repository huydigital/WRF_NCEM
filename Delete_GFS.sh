#!/bin/bash
set -x 
#print all task
set -e 
#stop when have a first error
#set -o pipefail
#still run command end  when error
# delete file GFS and keep newest 
#ls  /home/toandk/WRF/GFS/20???????? | head -n -1

GFSDIR=/home/toandk/WRF/GFS/

df -h $GFSDIR
#find $GFSDIR -name 20???????? | sort | head -n -1 | xargs -n 1 du -hs

find $GFSDIR -name 20???????? | sort | head -n -1 | xargs -n 1 -r rm -r

df -h $GFSDIR


WRFOUTDIR=/home/toandk/WRF/WRF_OUT/

df -h $WRFOUTDIR
#find $GFSDIR -name 20???????? | sort | head -n -1 | xargs -n 1 du -hs

find $WRFOUTDIR -name 20???????? | sort | head -n -1 | xargs -n 1 -r rm -r

# in future to archive SILAM result 
#find $WRFOUTDIR -name 20???????? | sort | head -n -1 | xargs -n 1 -r mv DIR

df -h $WRFOUTDIR

#rm -r /home/toandk/WRF/GFS/ 
