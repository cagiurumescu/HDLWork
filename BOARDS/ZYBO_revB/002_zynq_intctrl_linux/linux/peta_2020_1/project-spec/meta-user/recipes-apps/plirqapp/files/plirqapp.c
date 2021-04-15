/*******************************************************************************
MIT License

Copyright (c) 2019-2021 C. Adrian Giurumescu

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
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h> // for access
#include <fcntl.h>  // for open/close
#include <signal.h>
#include <sys/ioctl.h>

#define DEVICE_FILE "/dev/plirqdev"

// Must match defines in driver
#define IOCTL_MAJ 100
#define IOCTL_GET_IRQFLG _IOR(IOCTL_MAJ, 0, uint8_t *)
int fd=-1;

void sigio_callback(int sig) {
   uint8_t irq_flags;
   if (fd != -1) {
      ioctl(fd, IOCTL_GET_IRQFLG, &irq_flags);
   }
   if (irq_flags & 0x1) {
      printf("Got an F2P0 interrupt\n");
   }
   if (irq_flags & 0x2) {
      printf("Got an F2P1 interrupt\n");
   }
}

void sigint_callback(int sig) {
   close(fd);
   exit(1);
}

int main(int argc, char **argv) {
   int lint;

   signal(SIGIO, sigio_callback);
   signal(SIGINT, sigint_callback);

   if (access(DEVICE_FILE, F_OK)==-1) {
      printf("Could not access %s. Driver likely not loaded\n", DEVICE_FILE);
      return 0;
   }

   fd=open(DEVICE_FILE, O_RDWR);
   if (fd==-1){
      printf("Could not open %s\n", DEVICE_FILE);
   } else {
      printf("%s opened by PID=%d\n", DEVICE_FILE, getpid());
   }
   fcntl(fd, F_SETOWN, getpid());
   fcntl(fd, F_SETFL, FASYNC|fcntl(fd, F_GETFL));

   while (1) {
      sleep(2);
   }

   return 0;
}
