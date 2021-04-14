#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/io.h>
#include <linux/interrupt.h>

#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/of_platform.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Xilinx Inc.");
MODULE_DESCRIPTION("plirqdrv-simple driver to IRQ test");

#define DRIVER_NAME "plirqdrv"

#define MAX_IRQ 2
struct plirqdrv_local {
   int num_irq;
   int irq[MAX_IRQ];
};

static irqreturn_t plirqdrv_irq0(int irq, void *lp) {
   printk("F2P[0] interrupt\n");
   return IRQ_HANDLED;
}

static irqreturn_t plirqdrv_irq1(int irq, void *lp) {
   printk("F2P[1] interrupt\n");
   return IRQ_HANDLED;
}

static int plirqdrv_probe(struct platform_device *pdev) {
   struct resource *r_irq; /* Interrupt resources */
   struct device *dev = &pdev->dev;
   struct plirqdrv_local *lp = NULL;

   int rc = 0, i;
   dev_info(dev, "Device Tree Probing\n");

   lp = (struct plirqdrv_local *) kmalloc(sizeof(struct plirqdrv_local), GFP_KERNEL);
   if (!lp) {
      dev_err(dev, "Cound not allocate plirqdrv device\n");
      return -ENOMEM;
   }
   dev_set_drvdata(dev, lp);

   /* Get IRQs for the device */
   lp->num_irq = 0;
   for (i=0; i<MAX_IRQ; i++) {
      r_irq = platform_get_resource(pdev, IORESOURCE_IRQ, i);
      if (!r_irq) {
         dev_info(dev, "no IRQ found\n");
         continue;
      } else {
         lp->irq[lp->num_irq] = r_irq->start;
         if (i==0) {
            rc = request_irq(lp->irq[lp->num_irq], &plirqdrv_irq0, IRQF_TRIGGER_HIGH, "plirq[0]", lp);
         } else {
            rc = request_irq(lp->irq[lp->num_irq], &plirqdrv_irq1, IRQF_TRIGGER_RISING, "plirq[1]", lp);
         }
         if (rc) {
            dev_err(dev, "Could not allocate interrupt %d.\n",
                  lp->irq[lp->num_irq]);
            goto error2;
         }
         lp->num_irq++;
      }
   }
   dev_info(dev,"irq[0]=%d irq[1]=%d\n", lp->irq[0], lp->irq[1]);
   return 0;

error2:
   for (i=0; i<lp->num_irq; i++) {
      free_irq(lp->irq[i], lp);
   }
   kfree(lp);
   dev_set_drvdata(dev, NULL);
   return rc;
}

static int plirqdrv_remove(struct platform_device *pdev) {
   struct device *dev = &pdev->dev;
   struct plirqdrv_local *lp = dev_get_drvdata(dev);
   int i;
   for (i=0; i<lp->num_irq; i++) {
      free_irq(lp->irq[i], lp);
   }
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
