# Example on using interrupts with Zynq (level or edge interrupts)
## Notes
* Project uses Vivado 2019.1 or 2020.1
* If interrupt ports are made external to block design some UI sensitivity 
options get reset. Use the command below to force a certain interrupt type:
> set_property CONFIG.SENSITIVITY LEVEL_HIGH|LEVEL_LOW|EDGE_RISING|EDGE_FALLING [get_bd_ports IRQ_F2Px]
* Actually above does not work and gives us an error because the interrupt into IRQ_F2P port of processing system is only allowed values LEVEL_HIGH or EDGE_RISING.
* As discussed in the [forums](https://www.xilinx.com/support/answers/58942.html) we must use the Concat IP in the block design.
* We must use the XScuGic_SetPriorityTriggerType() call to set the type of interrupt to edge sensitive (default is level sensitive).
