# Design details
The design contains a MicroBlaze MCS instance. It uses the GPIO to send R/W
commands to the native interface of the MIG controller.

## MIG Writes
We only have 4 32-bit GPOs so 128 bits. We'll write the 128-bit DRAM word first
then the write address. Software will write GPO4 first and GPO1 last then write
GPO1 with address. Hardware generates an interrupt when transaction is pushed to
MIG controller.

## MIG Reads
We write GPO1 with read address. Hardware generates an interrupt when read
completed and 128-bit DRAM read word is available on GPI1-GPI4 (GPI1 is msb).

