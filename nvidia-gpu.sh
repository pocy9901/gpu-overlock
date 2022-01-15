#!/bin/bash
systemctl stop gdm.service
nvidia-smi -pm 1
nvidia-smi -pl 140

pcistr=$(nvidia-xconfig --query-gpu-info | grep 'PCI BusID' | awk '{print $4}')
pcis=(${pcistr// /})
i=0
rm /etc/X11/xorg-* -f
for pci in ${pcis[@]}
do
  nvidia-xconfig --allow-empty-initial-configuration --cool-bits=28 -o /etc/X11/xorg-$i.conf
  sed -i 's/Section "Device"/Section "Device"\n    BusID "'${pci}'"/g' /etc/X11/xorg-$i.conf
  i=`expr $i + 1`
done

i=0
for pci in ${pcis[@]}
do
  ps aux | grep -ai "Xorg" | grep -v grep | awk '{print $2}' | xargs kill -9
  sleep 1s
  X :0 -config /etc/X11/xorg-$i.conf &
  n=0
  while [ $n -lt 1 ];do
    sleep 3s
    c=`DISPLAY=:0 nvidia-settings  -a 'GPUGraphicsClockOffset[4]=100' -a 'GPUMemoryTransferRateOffset[4]=2000'`
    n=`echo $c | grep -ai  GPUGraphicsClockOffset | grep -v grep -c`
  done
  i=`expr $i + 1`
done
