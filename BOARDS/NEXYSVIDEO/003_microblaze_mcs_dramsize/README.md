# Design details
The design contains a MicroBlaze MCS instance. It uses the GPIO to send R/W
commands to the native interface of the MIG controller.

## MIG Writes
We only have 4 32-bit GPOs so 128 bits. We'll write the DRAM address (29bits)
first to GPO1 then write 128bit DRAM word to GPO3,GPO4 in two transactions.
(GPO3 is always the msb in the 128 bit word). See the software for details.

## MIG Reads
We write GPO1 with read address. Hardware generates an interrupt when read
completed and 128-bit DRAM read word is available on GPI1-GPI4 (GPI1 is msb).

## Addressing
Each lsb of address is a 2-byte word address (the memory is x16). Reading in
increments of 0x8 increments the 16byte/128bit word being addressed.

For example if we write the following data to address 0x0:
>WDATA[0]=0x12345678; [ 31: 0]
>WDATA[1]=0xABCDEF01; [ 63:32]
>WDATA[2]=0x87654321; [ 95:64]
>WDATA[3]=0x10FEDCBA; [127:96]

We read back the following from address 0x0:
>RDATA[0]=0x12345678
>RDATA[1]=0xABCDEF01
>RDATA[2]=0x87654321
>RDATA[3]=0x10FEDCBA
We read back the following from address 0x1:
>RDATA[0]=0xEF011234
>RDATA[1]=0x5678ABCD
>RDATA[2]=0xDCBA8765
>RDATA[3]=0x432110FE
We read back the following from address 0x2:
>RDATA[0]=0xABCDEF01
>RDATA[1]=0x12345678
>RDATA[2]=0x10FEDCBA
>RDATA[3]=0x87654321
We read back the following from address 0x3:
>RDATA[0]=0x5678ABCD
>RDATA[1]=0xEF011234
>RDATA[2]=0x432110FE
>RDATA[3]=0xDCBA8765

