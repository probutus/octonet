#include <linux/module.h>
#include <linux/init.h>
#include <linux/io.h>
#include <linux/delay.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Digital Devices GmbH / Octonet");
MODULE_DESCRIPTION("Hardware Low-Level Fixup for AT91SAM9G45");

static int __init octonet_hw_fixup_init(void)
{
    void __iomem *r;

    pr_info("Octonet: Starting Combined Hardware Fixup for Kernel 6.12...\n");

    /* 1. Matrix Fixup: CPU Priority on System Bus */
    r = ioremap(0xffffea00, 0x200);
    if (r) {
        writel((8 << 18) | (2 << 16), r + 0x50); // SCFG4
        writel(0x00000003, r + 0xa0);           // PRBS4
        iounmap(r);
        pr_info("Octonet: Bus Matrix priority set\n");
    } else {
        pr_err("Octonet: Failed to ioremap Matrix\n");
    }

    /* 2. Shutdown & Alarm Fixup */
    r = ioremap(0xfffffd10, 0x100);
    if (r) {
        writel(0x30003, r + 0x04); // SHDW_MR
        writel(0x02, r + 0xbc);    // Alarm Reset
        iounmap(r);
        pr_info("Octonet: Shutdown & Alarm fixed\n");
    } else {
        pr_err("Octonet: Failed to ioremap Shutdown controller\n");
    }

    /* 3. Slow Clock Fixup (Die 1.4s Sequenz) */
    r = ioremap(0xfffffd50, 0x4);
    if (r) {
        if (readl(r) == 1) {
            pr_info("Octonet: Starting Slow Clock XTAL sync (1.4s)...\n");
            writel(0x03, r); mdelay(1400);
            writel(0x0b, r); mdelay(1);
            writel(0x0a, r);
            pr_info("Octonet: Slow Clock XTAL stable\n");
        }
        iounmap(r);
    } else {
        pr_err("Octonet: Failed to ioremap Slow Clock\n");
    }

    return 0;
}

static void __exit octonet_hw_fixup_exit(void)
{
    pr_info("Octonet: Hardware Fixup Module unloaded\n");
}

module_init(octonet_hw_fixup_init);
module_exit(octonet_hw_fixup_exit);

