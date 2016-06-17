# Config File Migration Script for Cumulus Linux 2.x

- Identify files that have changed since install in `/etc, /root, /home`
- Optionally create a tar archive of these files to /mnt/persist/backup for archival and compare.
- Optionally migrate these file to the alternate slot after installing a new CL image.
- Ignore files that should never be backed up (blacklist)
- Automatically clears /mnt/persist of all files except ./backup and license files.
- Gives hotfix instructions if upgrading from a version before 2.5.3 due to RN-287
- All changes are submitted for user approval before being made, unless 'force' option is used
- Allows optional exclude of specific directories from archive or migration
- Write out debugging log to `/var/log/config_file_changes.log.gz` and store a copy in `/mnt/persist/backup/`
- Backup archive can be restored to a newly imaged switch via `tar -C / -xvf BACKUP_ARCHIVE_NAME`

- Ansible playbook provided to create backup archive from 2.5.  Can be used to migrate configs to 3.0


# Usage: Config File Migration Script

1. Copy the executable files from this repo to the switch user's home directory.
Note that the 'ppc_slot_setup' script is only needed for PowerPC architecture switches
<pre>
host$ git clone THIS_REPO_URL
host$ cd REPO_DIR  #e.g.: $ cd config-backup-upgrade-helper
host$ scp config_file_changes ppc_slot_setup cumulus@switch:.
</pre>

1. On the switch, run the script to see files that have changed since an initial install:
<pre>
cumulus@switch$ sudo ./config_file_changes
</pre>

1. Remove any files that you do not want pushed across to the other slot, if any. Example:
<pre>
sudo ./config_file_changes -x /home/cumulus/.git,/etc/passwd,/etc/shadow
</pre>

1. If using the '--sync' option, install the desired 2.5 new version to the other slot
<pre>
cl-img-install IMAGE-URL
</pre>

1. Push the files to the other slot:
<pre>
sudo ./config_file_changes -s -x LIST_OF_FILES_TO_EXCLUDE
</pre>

1. [OPTIONAL] Create a backup archive tar file and store it off-router.  Default switch location
is /mnt/persist/backup/.
<pre>
sudo ./config_file_changes -b  -x LIST_OF_FILES_TO_EXCLUDE
scp /mnt/persist/backup/SWITCHNAME-config-archive-DATE_TIME.tar.gz  user@host:.
</pre>
Note:  A backup can be restored to a newly imaged switch via:
<pre>
sudo tar -C / -xvf SWITCHNAME-config-archive-DATE_TIME.tar.gz
</pre>

1. Make the other slot primary and reload the switch
<pre>
sudo cl-img-select -sf
sudo reload
</pre>

1. If upgrading from a version prior to 2.5.3, apply the workaround for RN-287.  Instructions are
printed out when running the script.

### Detailed Description of Migration Tool Options:

```
sudo ./config_file_changes [-b] [-d backupdirname] [-n] [-s] [-f] [-x] [-h]
     
Determine changed config files. Optionally create backup archive or sync to other slot

no args - Default: Print output of changed config files to screen
-b, --backup, Create a backup archive of changed config files.
-d, --backup_dir [dir], Location to store backup archive. Default dir is /mnt/persist/backup
-n, --dryrun, Output to screen but don't create or remove any files
-s, --sync, Copy changed and added files to alternate slot
-f, --force, Used with -s. Do not ask before copying or removing files
-x, --exclude dirs, Exclude a comma separated list of dirs: e.g.  -x /root,/home
-h, --help, Show this message
```

# Caveats: Config File Migration Script

- Currently this tool is not tested on ARM platforms.

- On X86 platforms, this script does not clear out old files from alternate
  slot before migration.  This tool should only be used after cl-img-install
  creates a fresh install of an image.
 
- Clears out all of `/mnt/persist` except for backup archives and license files.
  Copy any desired files from `/mnt/persist` off the box before running this script.
  This is done because having any config files in `/mnt/persist` is a dangerous
  workflow that can result in configuration surprises after a reboot.

- As part of the migration operation, the alternate slot on x86 platforms is
  mounted to `/tmp/slotX_YYYY`. If the script terminates abnormally, this would
  leave the mount active and prevent cl-img-install from completing this install,
  in which case this error will be seen during the install:
<pre>
Logical volume "SYSROOTx" already exists in volume group "CUMULUS"
Failure: Problems creating/formatting partition SYSROOT
</pre>
   To clear this condition, do:
<pre>
sudo umount /tmp/slotX_YYYY
</pre> 

- Does not support certain old PowerPC platforms with Raw Flash implementations
    - Celestica/Penguin Arctica 4804i 1G (cel,kennisis)
    - Celestica/Penguin Arctica 4804X 10G (cel,redstone)
    - Celestica/Penguin Arctica 3200XL 40G (cel,smallstone)
    - Delta/Agema DNI-3448P (dni,3448p)

- Does not support finding or archiving changed config files in Cumulus Linux 3.0.

- Files are identified by their modification time, so a 'touch' on a file
  is considered a changed file.
  
- Symlinks are ignored.

- Backup archives should also be copied off the box as part of a HW failure
  and recovery plan if user doesn't use orchestration tools to provision
  and maintain configurations.
  
- Management Namespace is a deprecated feature as of 2.5.4, and is replaced
  with the Management VRF feature in Cumulus Linux 2.5.5 and 3.0.  Management Namespace
  files will NOT be automatically migrated when using this script, and any Namespace
  config files will be removed by the clean up of `/mnt/persist`.  If it is desired to continue
  using Mgmt Namespace in 2.5, the following procedure must be followed:
    - Follow the procedure listed in the Usage section above, stopping before running 'sudo reload'
    - Follow the upgrade procedure at the bottom of the Configuring a Management Namespace Knowledge
    Base Article at this link: <https://support.cumulusnetworks.com/hc/en-us/articles/202325278-Configuring-a-Management-Namespace>.
    Note: Be sure to Skip Step 7 'Install the Cumulus Linux image onto the switch', since that was done
    in the first procedure
    
  
- Third party packages and add-ons like cl-mgmtvrf are not installed in the new slot,
  although any package config files in /etc will be found and tagged to migrate.
  
- On x86 platforms, the script can detect if config files have been deleted since
  the initial install.  However there is no logic to remove those files from the
  alternate slot.  If removal of those files is desired on the alternate slot, they
  will have to be removed manually after rebooting into that slot.
  

# Ansible Playbook to Migrate Configs from 2.5 for 3.0 preparation

Attached is an ansible playbook designed to install and run the Config File Migration
script on a set of switches.  This is provided as a jumpstart to aid in the migration
of config files while upgrading from Cumulus Linux 2.5 to Cumulus Linux 3.0.  It also
provides a quick introduction to the power of orchestration tools to deploy Cumulus
Linux.

The playbook copies and executes the config_file_changes script with the --backup option
to create a backup archive, then retrieves that archive back to the ansible host as a
starting place to plan a migration of config files to 3.0.

Be aware that 2.5 configs are not guaranteed to work in 3.0.  Testing of the restore
operation and proper operation of the Cumulus Linux 2.5 config in Cumulus Linux 3.0
should be done on a non-production router or a Cumulus VX image, since every deployment
is unique. The Caveats section below will be updated with known compatibility issues as
they are discovered.
  

# Usage: Ansible Playbook CL_2.x_backup_archive.yml

- Install ansible on a host.  This script was tested with ansible version 1.9.3
- Check out this repo into a directory on the host
- Edit the ansible.hosts file in that dir and put in the actual switch names:
```
[upgradeTo3]
my_first_switch_name
my_second_switch_name
```

- Run playbook, specifying the ansible-hosts file and prompt for sudo passwd:
<pre>
ansible-playbook -i ./ansible.hosts -K CL_2.x_backup_archive.yml
</pre>

- A tar archive of the config files on your 2.5 switches will be fetched to a directory
  tree rooted at:
<pre>
./config_archive/SWITCHNAME/tmp/config_archive_DATESTAMP.XXXX/
</pre>
  
- The log file 'config_file_changes.log.gz' will also be stored in that tree

- A backup can be restored to a newly imaged switch via:
<pre>
sudo tar -C / -xvf SWITCHNAME-config-archive-DATE_TIME.tar.gz
</pre>

# Caveats for Migration between 2.5 and 3.0

- The goal of this script is to identify and back up files that should be considered
  to move from 2.5 to 3.0.  Each file in the archive should be examined to determine
  if it has been changed by the network administrator and if the changed files need to
  be migrated, merged, or not moved to 3.0.  Note that the default configuration files
  may have been changed between versions, in which case only changes should be merged.
  
- /etc/passwd and /etc/shadow should not be migrated to 3.0 directly. The ansible script
  explictly excludes these two files from the backup archive.  The default password for the
  'cumulus' user will need to be changed, and any locally created users should be added to
  the 3.0 installation after upgrade.

- The /etc/apt/sources.list and /sources.list.d/ files are not compatible with 3.0 and will
  be excluded from the config archive when using the ansible playbook.  Manually edit these
  files and add any custom repos to the sources.list files after upgrading to 3.0
  
- cl-mgmtvrf and Management namespaces in 2.5 are deprecated.  If you were using either of
  those tools, you will need to configure your 3.0 router for the new Management-VRF feature
  implementation as described in the 3.0 docs:
  https://docs.cumulusnetworks.com/display/DOCS/Management+VRF
  

