# Design details
This is an initial attempt to run Linux on NexysVideo using MicroBlaze. While
developing the project the following items were revealed:
- QSPI support seems broken
- no SD card support, needs driver and AXI2SDCARD IP.
- Ethernet requires paid 1G/2.5 Ethernet IP from Xilinx.
- Uart can be used at 9600 BAUD.

This leaves us with only the option of booting using JTAG and using 
initramfs for rootfs.

Another interesting caveat about this project (which is largely)
due to the fact that I wanted to keep the bd design in a known
location not stashed under Vivado's project was documented
[here](https://forums.xilinx.com/t5/Xilinx-IP-Catalog/IP-Flow-19-3460-Validation-failed-on-parameter-XML-INPUT-FILE/m-p/1154478#M8199)

The projects includes a custom IP for pushbutton to generate either EDGE or 
LEVEL interrupts. Notice that it is not necessary to generate a custom
device tree entry for this IP, Petalinux adds it by default including its 
interrupt.
