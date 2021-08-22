#!/bin/sh
echo ""
echo "This script will set up QEMU VM with Intel GVT-G support."
echo "This script isn't completely automatic."
echo "You have to do following things first: "
echo ""
echo " - Make sure your machine actually supports it"
echo " - Make sure your kernel supports GVT-G "
echo " - Set up correct boot parameters"
echo ">>> i915.enable_gvt=1 i915.enable_guc=0 intel_iommu=1 "
echo " - Make sure all kernel modules are loaded "
echo " - Add your user to kvm group"
echo " - add this to /etc/security/limits.conf"

echo " "
echo "Script has no sanitization, keep this in mind"
echo " "
echo "Enter VM name (e.g. vm0): "
read vm_name
# name=${name:-Richard}
vm_name=${vm_name:-vm0}
mkdir $vm_name
cd $vm_name
echo "Enter amount of cores (e.g. 1): "
read vm_core
vm_core=${vm_core:-1}
echo "Enter amount of threads per core (e.g. 1): "
read vm_threads
vm_threads=${vm_threads:-1}
echo "Enter size of HDD to create (e.g. 40G): "
read vm_hdd_size
vm_hdd_size=${vm_hdd_size:-40G}
qemu-img create -f qcow2 hdd.img $vm_hdd_size
echo "Enter RAM size (e.g. 4G): "
read vm_ram
vm_ram=${vm_ram:-4G}
echo " 
#!/bin/sh
# you may add here stuff that should be ran as sudo when VM is starting
# for ex. loading kernel modules 
modprobe kvmgt
cd /sys/bus/pci/devices/0000\:00\:02.0/
echo \"cf46b956-0c8f-4cf2-ba50-3f4db4e765c4\" >> mdev_supported_types/i915-GVTg_V5_4/create 
#you might want to change i915-GVTg_V5_4 to something else if this mode isnt supported
chmod 777 -R /dev/vfio/
" >> sudo.sh

echo "
#!/bin/sh
sudo ./sudo.sh
env INTEL_DEBUG  norbc
iso=\" \" 
if [ -f \"iso.iso\" ]; then
    iso=\"-drive file=iso.iso,media=cdrom  \" 
fi

qemu-system-x86_64 -enable-kvm \\
        -cpu host \\
        -smp $(($vm_core * $vm_threads)),cores=$vm_core,threads=$vm_threads,sockets=1 \\
        -drive file=hdd.img  \$iso \\
        -net nic,model=rtl8139 -net user \\
        -m $vm_ram \\
        -vga none \\
        -display gtk,gl=on,show-cursor=on\\
        -monitor stdio \\
        -device vfio-pci,sysfsdev=/sys/bus/pci/devices/0000:00:02.0/cf46b956-0c8f-4cf2-ba50-3f4db4e765c4,display=on,x-igd-opregion=on,ramfb=on,driver=vfio-pci-nohotplug\\
        -name \"$vm_name\" \\
        -device ich9-intel-hda \\
        -device hda-micro,audiodev=hda\\
        -audiodev pa,id=hda,server=unix:/run/user/\$UID/pulse/native\\
        -usbdevice tablet \\
         
        
read -n 1 -s -r -p \"Press any key to exit\"
" >> start_vm.sh
chmod +x sudo.sh
chmod +x start_vm.sh
echo "Now you can copy boot ISO to $vm_name and rename it to iso.iso"
read -n 1 -s -r -p "Press any key to exit"
