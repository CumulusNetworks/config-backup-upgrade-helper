#! /bin/bash
tmp_d=$(mktemp -d)
addedfilelist="Files Added since initial install"
changedfilelist="Files Changed since initial install"
deletedfilelist="Files Deleted since initial install"

echo Extracting install file to $tmp_d
sh /var/lib/cumulus/installer/onie-installer extract $tmp_d
cd $tmp_d

tar -t -v --exclude='bin' --exclude=boot --exclude=usr --exclude=sbin --exclude=dev --exclude=run --exclude=var --exclude=lib --full-time -f sysroot-release.tar.gz | egrep -v -- '^d|->'  > installlist.txt

#get the equivlent list from the router
find /etc /home /root -type f -exec ls -l {} \;  > locallist.txt
	


# Find files that are not in install - adds
## check for files in /etc and /root and /home that don't exist in install image - files that have been added
while read localfileline ; do
  localfilename1=$(echo $localfileline | awk '{print $9}')
  localfileline2=$(ls -l --full-time $localfilename1)
  #echo LLINE: $localfileline
  localdate=$(echo $localfileline2 | awk '{print $6" " $7}'  | awk -F '.' '{print $1}')
  localsize=$(echo $localfileline2 | awk '{print $5}')
  localfilename=$(echo $localfileline2 | awk '{print $9}')

  #echo ILINE: $localfileline

## How to get info from tar on a specific file:
##tar -t -v --full-time --no-anchored -f Downloads/Komodo-Edit-9.3.0-16396-linux-x86_64.tar.gz  support/which.py
##-rw-r--r-- komodo-build/komodo-build 13685 2015-10-27 15:53:10 Komodo-Edit-9.3.0-16396-linux-x86_64/support/which.py
## But I have already created the file list above, so just need to grep for the filename with a leading space and hope it is unique:
  
  installfileline=$(grep ".$localfilename" installlist.txt)
  if [ "$installfileline" = "" ]
  then
    # File is new, it doesn't exist in install archive
    echo "Local file is new since install: $localfilename"
    addedfilelist="${addedfilelist}\n${localfilename}"
  fi
  installfile=$(echo $installfileline | awk '{print $6}' | sed -e 's/^\.//')
  #echo FILE: $localfile
  installdate=$(echo $installfileline | awk '{print $4" " $5}')
  installsize=$(echo $installfileline | awk '{print $3}')
  #echo file: $installfile  localdate: $localdate installdate: $installdate localsize: $localsize installsize: $installsize
   ##  localfilelist.txt
  if [ "$localdate"! = "$installdate" ] || [ "$localsize" != "$installsize" ]
  then
    echo file: $installfile  localdate: $localdate installdate: $installdate localsize: $localsize installsize: $installsize
    changedfilelist="${changedfilelist}\n${localfilename}" 
  fi
done < locallist.txt


## Find files that have been deleted - deleted
while read installfileline ; do
  #echo ILINE: $installfileline
  installfile=$(echo $installfileline | awk '{print $6}' | sed -e 's/^\.//')
  localfileline=$(grep " $installfile" locallist.txt)
  if [ "$localfileline" = "" ]
  then
    # File was deleted, it doesn't exist on local system   
    echo "File was deleted since install: $installfile"
    deletedfilelist="${deletedfilelist}\n${localfilename}" 
  fi
#  #echo FILE: $installfile
#  installdate=$(echo $installfileline | awk '{print $4" " $5}')
#  installsize=$(echo $installfileline | awk '{print $3}')
#  localfileline=$(ls -l --full-time $installfile)
#  #echo LLINE: $localfileline
#  localdate=$(echo $localfileline | awk '{print $6" " $7" " $8}'  | awk -F '.' '{print $1}')
#  localsize=$(echo $localfileline | awk '{print $5}')
#  #echo file: $installfile  localdate: $localdate installdate: $installdate localsize: $localsize installsize: $installsize
#   ##  localfilelist.txt
#  if [ "$localdate"! = "$installdate" ] || [ "$localsize" != "$installsize" ]
#  then
#    echo file: $installfile  localdate: $localdate installdate: $installdate localsize: $localsize installsize: $installsize
#  fi
done < installlist.txt

cd ..
#rm -rf $tmp_d

printf "%b" "$addedfilelist"
echo
printf "%b" "$changedfilelist"
echo
printf "%b" "$deletedfilelist"

