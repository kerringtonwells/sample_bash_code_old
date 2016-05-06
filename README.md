The following files are included in my of portfolio (recent projects):

Calc_bytes_per_sec.sh - This script caculates the average speed of a stream in bytes per second. Takes information from several log files on multiple systems. 

Netvol.sh - Allows users to delete, create, and list <volumes> in a netapp.

Netsnap.sh -  This script was created to allow users to create and delete <snapshots> without logging into a netapp. Runs every morning via cron job

db_snapshot_clone.sh - Wrapper script created to use the features of netsnap.sh and netdb.sh to create a flex clone on a netapp using the latest snapshot, shutdown oracle, unmount the netapp, mount the db and restart oracle. 

Hound.pp - This puppet manifest file illustrates a few concepts. Inheritance of puppet modules, how to set firewall rules and permissions, setting selinux modes, setting file permissions, node definitions and creating hosts files for nodes in a RHEL linux environment. 

