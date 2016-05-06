#!/bin/bash

#This script as written to allow users to query a NETAPPDB without manually loging in

#DEFINE KEYS, DATABASE AND MODE
KEY=<removed/original/rsa/key/path>
USER=<removed.original.db.username>
RUN_CMD="ssh -i ${KEY} -l ${USER}"
MODE=cluster


RED="\033[0;31m\033[1m"
BLUE="\033[0;34m\033[1m"
LGRAY="\033[0;37m\033[1m"
NOCOLOR="\033\0m\033[0m"


function usage () {
"${LGRAY}Usage:${NOCOLOR}
${LGRAY}\n  (Arguments in brackets [] are optional)\n${NOCOLOR}
\t-n - NetApp filer management hostname/IP
\t-c - vFiler context
\t-v - volume name
\t-a - {action}
\t-h - show usage
\t\tlist - list volumes
\t\tusage - show volume usage 
\t\tclone - clone a volume 
\t\tdelete - delete a volume
\t-t - target volume name 
\t-s - Source snapshot
\t-l - Clone Latest snapshot 
${LGRAY}Examples:${NOCOLOR}
${BLUE}  List Volume Status${NOCOLOR}
  $(basename $0) -n filer_a [-c vfiler] [-v volume] -a list
${BLUE}  Show Volume Usage${NOCOLOR}
  $(basename $0) -n filer_a [-c vfiler] [-v volume] -a usage
${BLUE}  Clone a snapshot to a new volume${NOCOLOR}
  $(basename $0) -n filer_a [-c vfiler] [-v volume] -a clone -s 15min_snapshot -t TestBackup
\n"
	exit 1
}


while getopts ":n:c:v:a:hs:t:" opt; do
	case $opt in
		n)
			NETAPP=$OPTARG
			;;
		c)
			CONTEXT=$OPTARG
			VFILERRUN="vfiler run $CONTEXT"
			;;
		v)
			VOL=$OPTARG
			;;
		a)
			ACTION=$OPTARG
			;;
		s)
			SOURCE=$OPTARG
			;;
		t)
			TARGET=$OPTARG
			;;
		h)
			usage
			;;
		:)
			echo -e "${RED}\nOption -$OPTARG requires an argument.\n${NOCOLOR}" >&2
			usage
			;;
	esac
done

#LIST NETAPP USAGE
function volUsage () {
        local _remotecmd=$(ssh -i $KEY $USER@$NETAPP $VFILERRUN df -h $VOL |grep -v '_root\|.snapshot\|snap reserve\|vol0' |sed 's/    / /g')
        echo -e "${_remotecmd%x}"
}

#LIST NET APP VOLUMES
function volList () {
	 local _remotecmd=$(ssh -i $KEY $USER@$NETAPP $VFILERRUN vol show)
		
                echo -e "${_remotecmd%x}"
} 

#CLONE AN EXISTING VOLUME
function volClone () {
	 local _remotecmd=$(ssh -i $KEY $USER@$NETAPP $VFILERRUN volume clone create -flexclone $TARGET -type rw -parent-volume $VOL -parent-snapshot $SOURCE -junction-path /$TARGET |awk '{print $1}')
            echo -e "${_remotecmd%x}"
	    _remotecmd=$(ssh -i $KEY $USER@$NETAPP $VFILERRUN volume modify -volume $TARGET -policy default|awk '{print $1}')
	echo -e "${_remotecmd%x}"
}

#DELETE AN EXISTING VOLUME
function volDelete () {
	local _remotecmd=$(ssh -i $KEY $USER@$NETAPP $VFILERRUN set advanced\; volume unmount -volume $VOL\; volume offline -volume $VOL\; volume delete -volume $VOL)
	echo -e "${_remotecmd%x}"	
}

#CHECK FLAGS FUNCTION
function checkFlags () {

        if [ -z $NETAPP ];then
                        echo -e "\n${RED}You did not specify a filer to connect to.\n${NOCOLOR}"
                        usage
        fi

	if [ -z $ACTION ];then
			echo -e "\n${RED}You did not specify an action.\n${NOCOLOR}"
			usage
	fi

	if [[( "x$ACTION" == "xclone" && ( -z $SOURCE || -z $TARGET || -z $VOL ))]]; then 
	    echo -e "\n${RED}You must specify a volume, source, and target when cloning.\n${NOCOLOR}"
	usage
	fi
	
	if [[ "x$ACTION" == "xdelete" && -z $VOL ]]; then 
	    echo -e "\n${RED}You must specify a volume to delete.\n${NOCOLOR}"
	    usage
	fi
}

#SPECIFYING THAT THE CHECKFLAGS FUNCTION MUST RUN REGARDLESS OF THE CASE
checkFlags


case "$ACTION" in
	usage)
		volUsage
		;;
	list)
		volList
		;;
	clone)
	        volClone
		;;
	delete)
		volDelete
		;;
	*)
		usage
		;;
esac
