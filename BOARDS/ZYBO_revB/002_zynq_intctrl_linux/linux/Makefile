# vim: set noet:

ifeq ($(PETALINUX_VER),2020.1)
PETADIR:=peta_2020_1
endif
ifeq ($(PETALINUX_VER),2019.1)
PETADIR:=peta_2019_1
endif


$(PETADIR):
	petalinux-create --type project --template zynq --name $@
	cd $@ && petalinux-create --type modules --name plirqdrv --enable

config: $(PETADIR)
	cd $(PETADIR) && petalinux-config --get-hw-description=../hdf --silentconfig

build:
	cd $(PETADIR) && petalinux-build
	cd $(PETADIR) && petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot --kernel --force

sdcopy:
ifneq ($(MEDIADIR),)
	rm -rf $(MEDIADIR)/BOOT/*
	sudo rm -rf $(MEDIADIR)/rootfs/*
	cd $(PETADIR) && cp images/linux/BOOT.BIN   $(MEDIADIR)/BOOT
	cd $(PETADIR) && cp images/linux/image.ub   $(MEDIADIR)/BOOT
ifeq ($(PETALINUX_VER),2020.1)
	cd $(PETADIR) && cp images/linux/boot.scr   $(MEDIADIR)/BOOT
endif
	cd $(PETADIR) && cp images/linux/system.dtb $(MEDIADIR)/BOOT
	cd $(PETADIR) && sudo cp images/linux/rootfs.tar.gz $(MEDIADIR)/rootfs
	cd $(MEDIADIR)/rootfs && sudo tar -zxvf rootfs.tar.gz && sudo rm -f rootfs.tar.gz
	sudo umount $(MEDIADIR)/BOOT
	sudo umount $(MEDIADIR)/rootfs
endif

partsdcard:
	#sudo sfdisk -d /dev/mmcblk0 > mmcblk0.sfdisk
	sudo sfdisk /dev/mmcblk0 < mmcblk0.sfdisk
	sudo mkfs.vfat -n BOOT /dev/mmcblk0p1
	sudo mkfs.ext4 -L rootfs /dev/mmcblk0p2

.PHONY: config build
