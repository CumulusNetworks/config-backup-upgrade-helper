# Config File Migration script for Cumulus Linux 2.x

- Identify files that have changed since install in /etc, /root, /home
- Optionally create a tar archive of these files to /mnt/persist/backup for archival and compare.
- Optionally migrate these file to the alternate slot after installing a new CL image.
- Ignore files that should never be backed up (blacklist)
- Automatically clears /mnt/persist of all files except ./backup and license files.
- Gives hotfix instructions if upgrading from a version before 2.5.3 due to RN-287
- All changes are submitted for user approval before being made, unless 'force' option is used
- Allows optional exclude of specific directories from archive or migration
- Write out debugging log to /var/log/config_file_changes.log.gz and store a copy in /mnt/persist/backup/

- Ansible playbook provided to create backup archive from 2.5.  Can be used to migrate configs to 3.0

# Usage

1. Copy the files from this repo to the switch user's home directory

1. If using the 'sync' option, first install the desired new version
  using cl-img-install

1. Use Migration tool with desired options:

<pre><code>
sudo config_file_changes [-b] [-d backupdirname] [-n] [-s] [-f] [-x] [-h]
     
Determine changed config files. Optionally create backup archive or sync to other slot

no args - Default: Print output of changed config files to screen
-b, --backup, Create a backup archive of changed config files.
-d, --backup_dir [dir], Location to store backup archive. Default dir is /mnt/persist/backup
-n, --dryrun, Output to screen but don't create or remove any files
-s, --sync, Copy changed and added files to alternate slot
-f, --force, Used with -s. Do not ask before copying or removing files
-x, --exclude dirs, Exclude a comma separated list of dirs: e.g.  -x /root,/home
-h, --help, Show this message

</code></pre>


# Caveats for Config File Migration Script
- Currently this tool is not tested on ARM platforms.

- On X86 platforms, this script does not clear out old files from alternate
  slot before migration.  This tool should only be used after cl-img-install
  creates a fresh install of an image.
 
- Clears out all of /mnt/persist except for backup archives and license files.
  Copy any desired files from /mnt/persist off the box before running this script.
  This is done because having any config files in /mnt/persist is a dangerous
  workflow that can result in configuration surprises after a reboot.

- As part of the migration operation, the 2nd slot on x86 platforms is
  mounted to /tmp/slotx_yyyy. If the script terminates abnormally, this would
  leave the mount active and prevents cl-img-install from completing this install,
  with this error:
    'Logical volume "SYSROOTx" already exists in volume group "CUMULUS"'
    'Failure: Problems creating/formatting partition SYSROOT'.
   To clear this condition, do:  sudo umount /tmp/slot{x}_{yyyy} 

- Does not support certain old PowerPC platforms with Raw Flash implementations
    - Celestica/Penguin Arctica 4804i 1G (cel,kennisis)
    - Celestica/Penguin Arctica 4804X 10G (cel,redstone)
    - Celestica/Penguin Arctica 3200XL 40G (cel,smallstone)
    - Delta/Agema DNI-3448P (dni,3448p)

- Does not support 3.0 at this time

- Files are identified by their modification time, so a 'touch' on a file
  is considered a changed file

- Backup archives should also be copied off the box as part of a HW failure
  and recovery plan if user doesn't use orchestration tools to provision
  and maintain configurations.
  
- Third party packages and add-ons like cl-mgmtvrf are not installed in new slot,
  although any package config files in /etc will be found and tagged to migrate.
  
- On x86 platforms, the script can detect if config files have been deleted since
  the initial install.  However there is no logic to remove those files from the
  alternate slot.  If removal of those files is desired on the alternate slot, they
  will have to be removed manually after rebooting into that slot.
  

# Ansible Playbook to Migrate configs from 2.5 for 3.0 

Attached is an ansible playbook designed to install and run the script on a set of switches
This is provided as a jumpstart to aid in the migration of config files while upgrading
from Cumulus Linux 2.5 to Cumulus Linux 3.0.

The playbook copies and executes the config_file_changes script with the --backup option
to create a backup archive, then retrieves that archive back to the ansible host as a
starting place to plan a migration of config files to 3.0.

# Usage: Ansible Playbook CL_2.x_backup_archive.yml

- Install ansible on a host.  This script was tested with ansible version 1.9.3
- Check out this repo into a directory on the host
- Edit the ansible.hosts file in that dir and put in the actual switch names:
<pre><code>
[upgradeTo3]
my_first_switch_name
my_second_switch_name
</code></pre>

- Run playbook, specifying the ansible-hosts file and prompt for sudo passwd:
<pre><code>
ansible-playbook -i ./ansible.hosts -K CL_2.x_backup_archive.yml
</code></pre>

- A tar archive of the config files on your 2.5 switches will be fetched to a directory
  tree rooted at:
  <pre><code>
./config_archive/SWITCHNAME/tmp/config_archive_DATESTAMP.XXXX/
</pre></code>
  
- The log file 'config_file_changes.log.gz' will also be stored in that tree
  
# Caveats for Migration between 2.5 and 3.0

- The /etc/apt/sources.list and /sources.list.d/ files are not compatible with 3.0 and will
  be excluded from the config archive.  Manually edit these files and add any custom repos
  to the sources.list files after upgrading to 3.0
  
- cl-mgmtvrf in 2.5 is deprecated.  You will need to configure your 3.0 router for the
  new Management-VRF feature implementation as described in the 3.0 docs:
  https://docs.cumulusnetworks.com/display/DOCS/Management+VRF
  

