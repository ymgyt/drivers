#include "linux/kern_levels.h"
#include <linux/init.h>
#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/kdev_t.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("ymgyt");
MODULE_DESCRIPTION("devone");

#define DRIVER_NAME "devone"

static int devone_major = 0; /* dynamic allocation */
static int devone_devs = 2;
static struct cdev devone_cdev;

static int devone_open(struct inode *inode, struct file *file) {
  printk("%s: major %d minor %d (pid %d)\n", __func__, imajor(inode),
         iminor(inode), current->pid);

  inode->i_private = inode;
  file->private_data = file;

  printk("  i_private=%p private_data=%p\n", inode->i_private,
         file->private_data);

  return 0;
}

static int devone_close(struct inode *inode, struct file *file)
{
  printk("%s: major %d minor %d (pid %d)\n", __func__,
    imajor(inode), iminor(inode), current->pid);
  printk("  i_private=%p private_data=%p\n", inode->i_private, file->private_data);

  return 0;
}

struct file_operations devone_fops = {
    .open = devone_open,
    .release = devone_close,
};

static int __init devone_init(void) {
  dev_t dev = MKDEV(devone_major, 0);
  int alloc_ret = 0;
  int major;
  int cdev_err = 0;

  alloc_ret = alloc_chrdev_region(&dev, 0, devone_devs, DRIVER_NAME);
  if (alloc_ret)
    goto error;
  devone_major = major = MAJOR(dev);

  cdev_init(&devone_cdev, &devone_fops);
  devone_cdev.owner = THIS_MODULE;

  cdev_err = cdev_add(&devone_cdev, MKDEV(devone_major, 0), devone_devs);
  if (cdev_err)
    goto error;

  printk(KERN_ALERT "%s: driver(major %d) installed\n", DRIVER_NAME, major);
  return 0;

error:
  if (cdev_err == 0)
    cdev_del(&devone_cdev);

  if (alloc_ret == 0)
    unregister_chrdev_region(dev, devone_devs);

  return -1;
}

static void __exit devone_exit(void)
{
  dev_t dev = MKDEV(devone_major, 0);
  cdev_del(&devone_cdev);
  unregister_chrdev_region(dev, devone_devs);
  printk(KERN_ALERT "%s: driver unloaded\n", DRIVER_NAME);
}

module_init(devone_init);
module_exit(devone_exit);
