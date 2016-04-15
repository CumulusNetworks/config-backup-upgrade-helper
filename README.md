# Config File Migration script for Cumulus Linux 2.x

- Identify files that have changed since install in /etc, /root, /home
- Optionally create a tar archive of these files to /mnt/persist/backup for archival and compare.
- Optionally migrate these file to the alternate slot after installing a new CL image.
- Ignore files that should never be backed up (blacklist)
- Prompts user to automatically clear /mnt/persist of all files except ./backup and license files.
- Gives hotfix instructions if upgrading from a version before 2.5.3 due to RN-287
- All changes are submitted for user approval before being made, unless 'force' option is used
- Allows optional exclude of specific directories from archive or migration


# Usage

1. If using the 'sync' option, first install the desired new version
  using cl-img-install

1. Use Migration tool with desired options:

<pre><code>
sudo config_file_changes [-b] [-d backupdirname] [-n] [-q] [-s] [-f] [-v] [-x] [-h]
     
Determine changed config files. Optionally create backup archive or sync to other slot

no args - Default: Print output of changed config files to screen
-b, --backup, Create a backup archive of changed config files.
-d, --backup_dir [dir], Location to store backup archive. Default dir is /mnt/persist/backup
-n, --dryrun, Output to screen but don't create any files
-q, --quiet, No output to screen, only create any files requested  
-s, --sync, Copy changed and added files to alternate slot
-f, --force, Used with -s. Do not ask before copying files
-v, --debug, Verbose: Write out debugging logs to /var/log/config_file_changes.log
-x, --exclude dirs, Exclude a comma separated list of dirs: e.g.  -x /root,/home
-h, --help, Show this message

</code></pre>


# Caveats
- Does not clear out old files from alternate slot before migration.
  This tool should only be used after cl-img-install creates a fresh
  install of an image.
 
- Clears out all of /mnt/persist except for backup archives and license files.
  Backup any desired files off the box.

- As part of the migration operation, the 2nd slot on x86 platforms is
  mounted to /tmp/slotx_yyyy. If the script terminates abnormally, this would
  leave the mount active and prevents cl-img-install from running. To clear
  this condition, do:  sudo umount /tmp/slot{x}_{yyyy} 

- Does not support certain old PowerPC platforms with Raw Flash implementations
-- Celestica/Penguin Arctica 4804i 1G (cel,kennisis)
-- Celestica/Penguin Arctica 4804X 10G (cel,redstone)
-- Celestica/Penguin Arctica 3200XL 40G (cel,smallstone)
-- Delta/Agema DNI-3448P (dni,3448p)

- Does not support 3.0 at this time

- Files are identified by their modification time, so a 'touch' on a file
  is considered a changed file

- Backup archives should also be copied off the box as part of a HW failure
  and recovery plan if user doesn't use orchestration tools to provision
  and maintain configurations.

