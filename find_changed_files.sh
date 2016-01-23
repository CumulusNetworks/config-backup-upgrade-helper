tmp_d=$(mktemp -d)
echo Extracting install file to $tmp_d
sh /var/lib/cumulus/installer/onie-installer extract $tmp_d
cd $tmp_d

tar -t -v --exclude='bin' --exclude=boot --exclude=usr --exclude=sbin --exclude=dev --exclude=run --exclude=var --exclude=lib --full-time -f sysroot-release.tar.gz | egrep -v -- '^d|->'  > filelist.txt

while read installfileline ; do
  #echo ILINE: $installfileline
  installfile=$(echo $installfileline | awk '{print $6}' | sed -e 's/^\.//')
  #echo FILE: $installfile
  installdate=$(echo $installfileline | awk '{print $4" " $5}')
  installsize=$(echo $installfileline | awk '{print $3}')
  localfileline=$(ls -l --full-time $installfile)
  #echo LLINE: $localfileline
  localdate=$(echo $localfileline | awk '{print $6" " $7" " $8}'  | awk -F '.' '{print $1}')
  localsize=$(echo $localfileline | awk '{print $5}')
  #echo file: $installfile  localdate: $localdate installdate: $installdate localsize: $localsize installsize: $installsize
   ##  localfilelist.txt
  if [ "$localdate"! = "$installdate" ] || [ "$localsize" != "$installsize" ]
  then
    echo file: $installfile  localdate: $localdate installdate: $installdate localsize: $localsize installsize: $installsize
  fi
done <filelist.txt

cd ..
#rm -rf $tmp_d

## also need to check for files in /etc and /root and /home that don't exist in install image - files that have been added

