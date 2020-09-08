# Design details
The design contains a MicroBlaze MCS instance that exercises its external
interrupts and the GPI/O. One external interrupt is driven by a ~1/2 sec
timer. Software clears the interrupt in the xiomodule_app application. The
default application is just a simple Hello World.

