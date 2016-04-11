<pre><code>
Usage: sudo config_file_changes [-b] [-d backupdirname] [-n] [-q] [-s] [-f] [-v] [-x] [-h]
     
Determine changed config files. Optionally create backup archive or sync to other slot

no args - Default: Print output of changed config files to screen
-b, --backup, Create a backup archive of changed config files.
-c, --create, Create /etc/slotsync.conf - but don't call slotsync
-d, --backup_dir [dir], Location to store backup archive. Default dir is /mnt/persist/backup
-n, --dryrun, Output to screen but don't create any files
-q, --quiet, No output to screen, only create any files requested  
-s, --sync, Create /etc/slotsync.conf file and call slotsync to move file to alternate slot
-f, --force, Used with -s. Do not ask before running slotsync and moving files
-v, --debug, Verbose: Write out debugging logs to /etc/upgrade-tool-debug.log  
-x, --exclude dirs, Exclude a comma separated list of dirs: e.g.  -x /root,/home
-h, --help, Show this message

</code></pre>