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

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/slab.h>
//#include <linux/io.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/interrupt.h>
#include <linux/semaphore.h>
#include <linux/ioctl.h>
#include <linux/uaccess.h>

#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/of_platform.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Xilinx Inc.");
MODULE_DESCRIPTION("plirqdrv: a simple driver for IRQ test");

#define DRIVER_NAME  "plirqdrv"
#define DEVICE_NAME  "plirqdev"
#define CLASS_NAME   "plirqcls"
#define DEVICE_NUM   1 // only one device

#define MAX_IRQ 2
typedef struct _plirqdrv_t {
   int                     num_irq;
   int                     irq[MAX_IRQ];

   struct device           *l_pdev; // the platform device structure
   struct semaphore        l_sem; // only one userspace process can access
   struct cdev             l_cdev; // the char device cdev structure
   struct device           *l_dev; // the char device structure
   struct class            *l_class; // char device requires a class
   dev_t                   l_devt;

   pid_t                   pid;
   struct fasync_struct *  fasync_queue;
   uint8_t                 irq_flags;
} plirqdrv_t;

int ret; // for return values

static inline plirqdrv_t *to_plirqdrv_t(struct inode *inode) {
   return container_of(inode->i_cdev,plirqdrv_t,l_cdev);
}

static int plirqdev_open(struct inode *inode, struct file *filp) {
   plirqdrv_t *lp = to_plirqdrv_t(inode);
   struct task_struct *current_task = current;

   if (down_trylock(&lp->l_sem)) {
      dev_alert(lp->l_pdev, "cannot open device (used by PID = %d)\n", lp->pid);
      return -1;
   }

   lp->pid = current_task->pid;
   dev_info(lp->l_pdev, "device opened by PID = %d\n", lp->pid);

   return 0;
}

static int plirqdev_release(struct inode *inode, struct file *filp) {
   plirqdrv_t *lp = to_plirqdrv_t(inode);
   dev_info(lp->l_pdev, "device closed by PID = %d\n", lp->pid);
   up(&lp->l_sem);
   return 0;
}

static int plirqdev_fasync(int fd, struct file *filp, int on) {
   plirqdrv_t *lp = to_plirqdrv_t(filp->f_inode);
   return fasync_helper(fd,filp, on, &lp->fasync_queue);
}

#define IOCTL_MAJ 100
#define IOCTL_GET_IRQFLG _IOR(IOCTL_MAJ, 0, uint8_t *)
static long plirqdev_ioctl(struct file *filp, unsigned int cmd, unsigned long arg) {
   plirqdrv_t *lp = to_plirqdrv_t(filp->f_inode);

   switch (cmd) {
      case IOCTL_GET_IRQFLG:
         copy_to_user((uint8_t *)arg, &lp->irq_flags, sizeof(uint8_t));
         lp->irq_flags = 0;
         break;
      default:
         break;
   }

   return 0;
}

static struct file_operations plirqdrv_fops = {
   .owner = THIS_MODULE, // to prevent driver unload while device file open
   .open = plirqdev_open,
   .release = plirqdev_release,
   .fasync = plirqdev_fasync,
   .unlocked_ioctl = plirqdev_ioctl
};

static irqreturn_t plirqdrv_irq0(int irq, void *lp_in) {
   plirqdrv_t *lp = (plirqdrv_t *)lp_in;
   lp->irq_flags |= 0x1;
   kill_fasync(&lp->fasync_queue, SIGIO, POLL_IN);
   return IRQ_HANDLED;
}

static irqreturn_t plirqdrv_irq1(int irq, void *lp_in) {
   plirqdrv_t *lp = (plirqdrv_t *)lp_in;
   lp->irq_flags |= 0x2;
   kill_fasync(&lp->fasync_queue, SIGIO, POLL_IN);
   return IRQ_HANDLED;
}

static int plirqdrv_probe(struct platform_device *pdev) {
   struct resource *r_irq;
   struct device *dev = &pdev->dev;
   plirqdrv_t *lp = NULL;

   int i;
   dev_info(dev, "device tree probing\n");

   // allocate driver structure kernel memory
   lp = (plirqdrv_t *) kmalloc(sizeof(plirqdrv_t), GFP_KERNEL);
   if (!lp) {
      dev_err(dev, "could not allocate driver structure space\n");
      return -ENOMEM;
   }
   lp->l_pdev = &pdev->dev;
   dev_set_drvdata(dev, lp);

   // get the IRQs
   lp->num_irq = 0;
   for (i=0; i<MAX_IRQ; i++) {
      r_irq = platform_get_resource(pdev, IORESOURCE_IRQ, i);
      if (!r_irq) {
         dev_info(dev, "no IRQ found\n");
         continue;
      } else {
         lp->irq[lp->num_irq] = r_irq->start;
         if (i==0) {
            ret = request_irq(lp->irq[lp->num_irq], &plirqdrv_irq0, IRQF_TRIGGER_HIGH, "plirq[0]", lp);
         } else {
            ret = request_irq(lp->irq[lp->num_irq], &plirqdrv_irq1, IRQF_TRIGGER_RISING, "plirq[1]", lp);
         }
         if (ret) {
            dev_err(dev, "could not allocate interrupt %d.\n",
                  lp->irq[lp->num_irq]);
            goto reqirq_error;
         }
         lp->num_irq++;
      }
   }
   dev_info(dev,"irq[0]=%d irq[1]=%d\n", lp->irq[0], lp->irq[1]);

   // get device major number dynamically
   ret=alloc_chrdev_region(&lp->l_devt, 0/*baseminor*/, DEVICE_NUM, DEVICE_NAME);
   if (ret<0) {
      dev_alert(dev, "could not allocate major number\n");
      goto allocmaj_error;
   }
   dev_info(dev, "allocated major number %d\n", MAJOR(lp->l_devt));
   // we can use either device_create (which req. creating a class, or mknod which doesn't)
   lp->l_class = class_create(THIS_MODULE, CLASS_NAME);
   if (!lp->l_class) {
      dev_err(dev, "could not create device class\n");
      ret = -ENODEV;
      goto classcreate_error;
   }
   lp->l_dev = device_create(lp->l_class, NULL/*parent*/, lp->l_devt, NULL/*drvdata*/, DEVICE_NAME);
   if (!lp->l_dev) {
      dev_err(dev, "could not create device\n");
      ret = -ENODEV;
      goto devicecreate_error;
   }
   cdev_init(&lp->l_cdev, &plirqdrv_fops);
   ret = cdev_add(&lp->l_cdev, lp->l_devt, DEVICE_NUM);
   if (ret<0) {
      dev_err(dev, "could not add char device to kernel\n");
      goto chrdeviceadd_error;
   }
   dev_info(dev, "added char device to kernel (%08x)\n", lp);

   sema_init(&lp->l_sem,1);
   lp->irq_flags = 0;

   return 0;
chrdeviceadd_error:
   device_destroy(lp->l_class,lp->l_devt);
devicecreate_error:
   class_destroy(lp->l_class);
classcreate_error:
   unregister_chrdev_region(lp->l_devt, DEVICE_NUM);
allocmaj_error:
reqirq_error:
   for (i=0; i<lp->num_irq; i++) {
      free_irq(lp->irq[i], lp);
   }
   kfree(lp);
   dev_set_drvdata(dev, NULL);
   return ret;
}

static int plirqdrv_remove(struct platform_device *pdev) {
   struct device *dev = &pdev->dev;
   plirqdrv_t *lp = dev_get_drvdata(dev);
   int i;

   // remove the device
   device_destroy(lp->l_class,lp->l_devt);
   // remove the device class
   class_destroy(lp->l_class);
   // dealloc major number
   unregister_chrdev_region(lp->l_devt, DEVICE_NUM);
   // free the IRQs
   for (i=0; i<lp->num_irq; i++) {
      free_irq(lp->irq[i], lp);
   }
   // dealloc driver structure
   kfree(lp);

   dev_set_drvdata(dev, NULL);
   return 0;
}

#ifdef CONFIG_OF
static struct of_device_id plirqdrv_of_match[] = {
   { .compatible = "xlnx,plirqdrv", },
   { /* end of list */ },
};
MODULE_DEVICE_TABLE(of, plirqdrv_of_match);
#else
# define plirqdrv_of_match
#endif


static struct platform_driver plirqdrv_driver = {
   .driver = {
      .name             = DRIVER_NAME,
      .owner            = THIS_MODULE,
      .of_match_table   = plirqdrv_of_match,
   },
   .probe      = plirqdrv_probe,
   .remove     = plirqdrv_remove,
};

static int __init plirqdrv_init(void) {
   return platform_driver_register(&plirqdrv_driver);
}


static void __exit plirqdrv_exit(void) {
   platform_driver_unregister(&plirqdrv_driver);
}

module_init(plirqdrv_init);
module_exit(plirqdrv_exit);
