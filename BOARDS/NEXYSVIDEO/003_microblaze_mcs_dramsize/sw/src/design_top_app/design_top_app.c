/*******************************************************************************
MIT License

Copyright (c) 2019-2020 Claudiu Giurumescu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*******************************************************************************/
#include "xparameters.h"
#include "xstatus.h"
#include "xiomodule.h"
#include "xil_exception.h"
#include "xil_printf.h"

#define IOMODULE_DEVICE_ID XPAR_IOMODULE_0_DEVICE_ID
// first external interrupt
#define IOMODULE_INTR_ID  16

static XIOModule ub_iomodule;
volatile static u8 interrupt_ackd = 0;

XStatus setup_interrupt(XIOModule *ub_iomodule_ptr);
void interrupt_ack(void *callback_ref);
void interrupt_wait(void);
void dram_write(XIOModule *ub_iomodule_ptr, u32 dram_addr, u32* wdata);
void dram_read(XIOModule *ub_iomodule_ptr, u32 dram_addr, u32* rdata);

/****************************************************************************
* main
****************************************************************************/
int main(void) {
    XStatus status;
    u32 addr = 0x00000028;
    u32 wdata[4];
    u32 rdata[4];

    // Initialize IOModule driver
    status = XIOModule_Initialize(&ub_iomodule, IOMODULE_DEVICE_ID);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    // Self-test
    status = XIOModule_SelfTest(&ub_iomodule);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    // Setup interrupts
    status = setup_interrupt(&ub_iomodule);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    wdata[0]=0x12345678;
    wdata[1]=0xABCDEF01;
    wdata[2]=0x87654321;
    wdata[3]=0x10FEDCBA;

    dram_write(&ub_iomodule,addr,wdata);
    dram_read(&ub_iomodule,addr,rdata);
    for (int i=1; i<=4; i++) {
       xil_printf("RDATA[%d]=0x%08x\r\n",i-1,rdata[i-1]);
    }
    xil_printf("\r\n");
    dram_read(&ub_iomodule,addr+1,rdata);
    for (int i=1; i<=4; i++) {
       xil_printf("RDATA[%d]=0x%08x\r\n",i-1,rdata[i-1]);
    }
    xil_printf("\r\n");
    dram_read(&ub_iomodule,addr+2,rdata);
    for (int i=1; i<=4; i++) {
       xil_printf("RDATA[%d]=0x%08x\r\n",i-1,rdata[i-1]);
    }
    xil_printf("\r\n");
    dram_read(&ub_iomodule,addr+3,rdata);
    for (int i=1; i<=4; i++) {
       xil_printf("RDATA[%d]=0x%08x\r\n",i-1,rdata[i-1]);
    }
    xil_printf("Done testing addr=0x%08x\r\n", addr);

    for (addr=(1<<28); addr>=8; addr>>=1) {
       wdata[0]=addr;
       wdata[1]=addr;
       wdata[2]=addr;
       wdata[3]=addr;
       dram_write(&ub_iomodule,addr,wdata);
    }
    dram_read(&ub_iomodule,0x0,rdata);
    xil_printf("DRAM size is %d Mbytes\r\n", (rdata[0]<<1)>>20); // address is 2-byte word address

    return XST_SUCCESS;
}

/****************************************************************************
* This function connects the interrupt handler of 
* the IO Module to the processor.
****************************************************************************/
XStatus setup_interrupt(XIOModule *ub_iomodule_ptr) {
   XStatus status;

   // Connect the interrupt handler that will be called when an interrupt * for the device occurs,
   status = XIOModule_Connect(ub_iomodule_ptr, IOMODULE_INTR_ID, (XInterruptHandler) interrupt_ack, (void *)0);
   if (status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   // Start the IO Module such that interrupts are enabled for all devices that cause interrupts.
   status = XIOModule_Start(ub_iomodule_ptr);
   if (status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   // Enable interrupts for the device and then cause interrupts so the handlers will be called.
   XIOModule_Enable(ub_iomodule_ptr, IOMODULE_INTR_ID);
   // Initialize the exception table.
   Xil_ExceptionInit();
   // Register the IO module interrupt handler with the exception table.
   Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XIOModule_DeviceInterruptHandler, (void*) 0);
   // Enable exceptions.
   Xil_ExceptionEnable();

   return XST_SUCCESS;
}

/****************************************************************************
* interrupt handler
****************************************************************************/
void interrupt_ack(void *callback_ref) {
    // Indicate the interrupt has been processed using a shared variable.
   interrupt_ackd = 1;
}

/****************************************************************************
* interrupt wait
****************************************************************************/
void interrupt_wait(void) {
   while (interrupt_ackd==0);
   interrupt_ackd=0;
}
/****************************************************************************
* DRAM writes
****************************************************************************/
void dram_write(XIOModule *ub_iomodule_ptr, u32 dram_addr, u32* wdata) {
   // write wraddr
   dram_addr = (dram_addr&0x1FFFFFFF)|(4<<29);
   XIOModule_DiscreteWrite(ub_iomodule_ptr,1,dram_addr);
   interrupt_wait();

   // latch [127:64]
   XIOModule_DiscreteWrite(ub_iomodule_ptr,3,wdata[3]); // [127:96]
   XIOModule_DiscreteWrite(ub_iomodule_ptr,4,wdata[2]); // [95:64]
   dram_addr = (dram_addr&0x1FFFFFFF)|(6<<29);
   XIOModule_DiscreteWrite(ub_iomodule_ptr,1,dram_addr);
   interrupt_wait();

   // latch [63:0]
   XIOModule_DiscreteWrite(ub_iomodule_ptr,3,wdata[1]); // [63:32]
   XIOModule_DiscreteWrite(ub_iomodule_ptr,4,wdata[0]); // [31:0]
   dram_addr = (dram_addr&0x1FFFFFFF)|(7<<29);
   XIOModule_DiscreteWrite(ub_iomodule_ptr,1,dram_addr);
   interrupt_wait();

   // clear transaction + wait for transaction complete
   dram_addr = (dram_addr&0x1FFFFFFF)|(0<<29);
   XIOModule_DiscreteWrite(ub_iomodule_ptr,1,dram_addr);
   interrupt_wait();
}

/****************************************************************************
* DRAM reads
****************************************************************************/
void dram_read(XIOModule *ub_iomodule_ptr, u32 dram_addr, u32* rdata) {
    // write rdaddr + wait for read data
    dram_addr = (dram_addr&0x1FFFFFFF)|(5<<29);
    XIOModule_DiscreteWrite(ub_iomodule_ptr,1,dram_addr);
    interrupt_wait();
    // data will be available in GPI
    // could do read here or after transaction complete
    // clear transaction + wait for transaction complete
    dram_addr = (dram_addr&0x1FFFFFFF)|(0<<29);
    XIOModule_DiscreteWrite(ub_iomodule_ptr,1,dram_addr);
    interrupt_wait();

    rdata[0]=XIOModule_DiscreteRead(ub_iomodule_ptr,4);
    rdata[1]=XIOModule_DiscreteRead(ub_iomodule_ptr,3);
    rdata[2]=XIOModule_DiscreteRead(ub_iomodule_ptr,2);
    rdata[3]=XIOModule_DiscreteRead(ub_iomodule_ptr,1);
}
