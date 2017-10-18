#!/bin/bash

# This script shoud run at root.
USBDEVID=$( udevadm info --query=path --name=$1 | cut -f 8 -d '/' )

sleep 1
echo $USBDEVID | tee /sys/bus/usb/drivers/usb/unbind
sleep 1
echo $USBDEVID | tee /sys/bus/usb/drivers/usb/bind

