#!/bin/bash

CDDRV="/dev/sr0"

# 
wait_insert()
{
	eject $CDDRV

	# Wait inserted
	while :
	do
		cdstat=$( cdinfo $CDDRV 2>&1 | grep -q "no_disc" || echo "1" )
		if [ $cdstat ];
		then
			break
		fi
		sleep 1
	done

        echo ""
	echo "CD INSERTED."
}


# Erase CD-RW.
rw_erase()
{
	wodim dev=$CDDRV blank=fast
	eject $CDDRV
}

# Write disk image
writeimg()
{
	if [ -e $1 ];
	then
		iso="$1"
	else
		echo "ERR: FILE $1 NOT FOUND!"
		exit 1
	fi

	# Write image
	wodim dev=$CDDEV $1

	# Temporary eject and insert
	sdparm --command=unlock $CDDEV
	sg_start -e -i $CDDEV
	sg_start -l -i $CDDEV


	# Verify


	sleep 1
}

# Verify MD5 on start


# Main Loop

while :
do
	clear
	echo ""
	echo " === COCONWRITER ==="
	echo ""

	# Show image ids
	find "./" -type f -iname "?.imagedef" | sort | while read -r defname
	do
		defnum=$( basename $defname .imagedef )
		source $defname
		echo " $defnum : $IMG_NAME"
	done
	echo ""

	# input id
	read -p "INPUT IMAGE NO. : " -n1 imageid

	if [ -e "${imageid}.imagedef" ];
	then
		# open define file
		source ${imageid}.imagedef

		# first, open tray and wait when closed
		clear
		echo ""
		echo "=== PLEASE INSERT CD ==="
		wait_insert

		if [ $RW_ERASE ];
		then
			rw_erase
		else
			writeimg $IMG_ISOFILE 
		fi
	else
		echo ""
		echo ""
		echo "ERR: NO DEFINE FOR ${imageid}!"
		sleep 2
	fi

done

