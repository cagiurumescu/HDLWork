/*******************************************************************************
MIT License

Copyright (c) 2019-2021 Claudiu Giurumescu

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

#include <stdio.h>
#include "xparameters.h"
#include "xil_exception.h"
#include "xscugic.h"

static XScuGic_Config *GicConfig;   // configuration of interrupt controller
XScuGic InterruptController;        // the interrupt controller instance

void custom_interrupt0_handler(void *callback_ref);
void custom_interrupt1_handler(void *callback_ref);
volatile static int interrupt0_processed = 0;
volatile static int interrupt1_processed = 0;

int main() {
   int Status;

   GicConfig = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
   if (!GicConfig) {
      printf("ERROR: could not find interrupt controller configuration\n");
      return XST_FAILURE;
   }

   Status = XScuGic_CfgInitialize(&InterruptController, GicConfig, GicConfig->CpuBaseAddress);
   if (Status != XST_SUCCESS) {
      printf("ERROR: could not initialize interrupt controller");
      return XST_FAILURE;
   }

   Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, 
         (Xil_ExceptionHandler) XScuGic_InterruptHandler,
         &InterruptController);
   Xil_ExceptionEnable();

   // XPAR_FABRIC_IRQ_F2P0_INTR - level interrupt asserting every 1.2 sec for 2.56 us
   Status = XScuGic_Connect(&InterruptController, XPAR_FABRIC_IRQ_F2P0_INTR,
         (Xil_ExceptionHandler)custom_interrupt0_handler,
         (void *)&InterruptController);
   if (Status != XST_SUCCESS) {
      printf("ERROR: could not connect interrupt controller to interrupt routine");
      return XST_FAILURE;
   }

   // XPAR_FABRIC_IRQ_F2P1_INTR - edge triggered interrupt every 1.2 sec
   Status = XScuGic_Connect(&InterruptController, XPAR_FABRIC_IRQ_F2P1_INTR,
         (Xil_ExceptionHandler)custom_interrupt1_handler,
         (void *)&InterruptController);
   if (Status != XST_SUCCESS) {
      printf("ERROR: could not connect interrupt controller to interrupt routine");
      return XST_FAILURE;
   }
   // set to edge triggered
   XScuGic_SetPriorityTriggerType(&InterruptController,XPAR_FABRIC_IRQ_F2P1_INTR, 
         160/*default priority, 0 highest, incr by 8*/,
         0b11);

   XScuGic_Enable(&InterruptController, XPAR_FABRIC_IRQ_F2P0_INTR);
   XScuGic_Enable(&InterruptController, XPAR_FABRIC_IRQ_F2P1_INTR);

   while (1) {
      if (interrupt0_processed) {
         printf("\nGot an F2P0 interrupt\n");
         interrupt0_processed = 0;
      }
      if (interrupt1_processed) {
         printf("\nGot an F2P1 interrupt\n");
         interrupt1_processed = 0;
      }
   }
   return 0;
}

void custom_interrupt0_handler(void *callback_ref) {
   printf(".");
   interrupt0_processed = 1;
}

void custom_interrupt1_handler(void *callback_ref) {
   printf(">");
   interrupt1_processed = 1;
}
