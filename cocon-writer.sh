#/bin/bash

# cocon-writer
# needed tools : sdparm, wodim, sg3-utils, eject

CDDRV="/dev/sr0"

# Wait inserted CD-R
wait_insert()
{
	eject $CDDRV
	echo "PLEASE INSERT BLANK CD."

	# Wait inserted
	while :
	do
		cur="$( sg_get_config $CDDRV 2>&1 | grep "Current profile:" )"
		if [ -n "$cur" ];
		then
			# Check profile
			cdprof=$( echo $cur | grep "Current profile: " | cut -d ":" -f 2 | tr -d ' ' )
			echo "TYPE: $cdprof"
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
	wodim -v dev=$CDDRV blank=fast
	eject $CDDRV
}

# Write disk image
writeimg()
{
	if [ -e $1 -a -n "$2" ];
	then
		iso="$1"
		iso_md5="$2"
	else
		echo "ERR: FILE $1 NOT FOUND!"
		exit 1
	fi

	# Write image
	wodim -v -dao dev=$CDDRV -data $iso
	echo "WRITE COMPLETE (RETURN: $?)."

	# Temporary eject and insert
	sdparm --command=unlock $CDDRV
	sg_start -e -i $CDDRV
	sg_start -l -i $CDDRV

	# Verify
	while :
	do
		cd_md5all=$( md5sum $CDDRV 2> /dev/null )
		cd_md5stat=$?

		if [ $cd_md5stat -ne 0 ];
		then
			# I/O Error. retry.
			sleep 1
			continue
		fi
		cd_md5=$( echo $cd_md5all | cut -d " " -f 1 )

		if [ "$iso_md5" != "$cd_md5" ];
		then
			# Inccorect checksum.
			echo "ERR: Incorrect MD5!"
			echo " ISO $iso_md5"
			echo " CDR $cd_md5"
			sleep 10
		fi
		break
	done

	# eject cd
	eject $CDDRV

	#
	echo " WRITE OK."
	sleep 2
}

# Verify MD5 on start
find "./" -type f -iname "?.imagedef" | sort | while read -r defname
do
	defnum=$( basename $defname .imagedef )
	source $defname

	if [ -n "$IMG_ISOFILE" ];
	then
		chk_md5=$( md5sum $IMG_ISOFILE | cut -d " " -f 1 )
		if [ "$IMG_MD5" != "$chk_md5" ];
		then
			echo "$IMG_ISOFILE : MD5 incorrect!"
			read -n 1 -s -p "Press any key to continue."
			exit 1
		fi
		echo "$IMG_NAME ($IMG_ISOFILE) OK."
	fi
done


# Main menu
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
			writeimg $IMG_ISOFILE $IMG_MD5
		fi
	else
		echo ""
		echo ""
		echo "ERR: NO DEFINE FOR ${imageid}!"
		sleep 2
	fi

done

