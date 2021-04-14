
[//]: # (vim: set tw=80:)
[//]: # (NB: first line MUST BE empty)
# Example on using interrupts with Zynq (level or edge interrupts) in Linux
## Notes
* This designs has similar hardware as [here](../001_zynq_intctrl) except the
Ethernet MIO was added to the PS to support PetaLinux.
* I noticed some issues with level interrupt detection in Linux using either
PetaLinux 2019.1 or 2020.1. Namely, in the design above the edge of the F2P[1] 
interrupt occurs some 2.56 us before the level of F2P[0] starts asserting.
F2P[0] level interrupt stays asserted for 2.56 us. Yet F2P[0] level interrupt is
never detected in Linux according to ``cat /proc/interrupts``. That same design
detects both interrupts when using a baremetal application.
* What is more puzzling is that changing F2P[0] to a **IRQF_TRIGGER_RISING** 
mode when calling ``request_irq`` in the driver makes the interrupt work
(despite the interrupt being implemented as a level high interrupt in the 
device tree). Also if the second interrupt is ignored in the driver (no
second call to ``request_irq``), then the level high interrupt F2P[0] works.
* Modified the hw to produce the edge interrupt every ~2 secs, and the level
interrupt every ~1 sec. In this case both interrupts are detected properly,
and interrupt count is correct (there are twice as many F2P[0] interrupts
compared to F2P[1] interrupts).
* Remains to be investigated if the length of assertion (currently 2.56 us)
of level interrupt has any influence on missed interrupts when edge and level
interrupts are close together. Also, unclear if closeness in time has any 
relation to F2P[0] not being detected. The situation is troubling as 
different devices may generate this interrupt pattern and thus one device 
would never trigger.
