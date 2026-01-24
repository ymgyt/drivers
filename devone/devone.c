#include <asm-generic/errno-base.h>
#include <linux/capability.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/ioctl.h>
#include <linux/kdev_t.h>
#include <linux/kern_levels.h>
#include <linux/module.h>
#include <linux/spinlock.h>

#include "devone_ioctl.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("ymgyt");
MODULE_DESCRIPTION("devone");

#define DRIVER_NAME "devone"

static int devone_major = 0; /* dynamic allocation */
static int devone_minor = 0; /* static allocation */
static int devone_devs = 1;
static struct cdev devone_cdev;
static struct class *devone_class = NULL;
static struct device *devone_device = NULL;

struct devone_data {
  unsigned char val;
  rwlock_t lock;
};

static int devone_open(struct inode *inode, struct file *file) {
  struct devone_data *p;

  printk("%s: major %d minor %d (pid %d)\n", __func__, imajor(inode),
         iminor(inode), current->pid);

  p = kmalloc(sizeof(struct devone_data), GFP_KERNEL);
  if (p == NULL) {
    printk("%s: No memory\n", __func__);
    return -ENOMEM;
  }

  p->val = 0xff;
  rwlock_init(&p->lock);

  inode->i_private = inode;
  file->private_data = p;

  printk("  i_private=%p private_data=%p\n", inode->i_private,
         file->private_data);

  return 0;
}

static int devone_close(struct inode *inode, struct file *file) {
  printk("%s: major %d minor %d (pid %d)\n", __func__, imajor(inode),
         iminor(inode), current->pid);
  printk("  i_private=%p private_data=%p\n", inode->i_private,
         file->private_data);

  if (file->private_data) {
    kfree(file->private_data);
    file->private_data = NULL;
  }

  return 0;
}

static ssize_t devone_write(struct file *filep, const char __user *buf,
                            size_t count, loff_t *f_pos) {
  struct devone_data *p = filep->private_data;
  unsigned char val;
  int retval = 0;

  printk("%s: count %zu pos %lld\n", __func__, count, *f_pos);

  if (count >= 1) {
    if (copy_from_user(&val, &buf[0], 1)) {
      retval = -EFAULT;
      goto out;
    }
    write_lock(&p->lock);
    p->val = val;
    write_unlock(&p->lock);
    retval = count;
  }

out:
  return (retval);
}

static ssize_t devone_read(struct file *filep, char __user *buf, size_t count,
                           loff_t *f_pos) {
  struct devone_data *p = filep->private_data;
  int i;
  unsigned char val;
  int retval;

  read_lock(&p->lock);
  val = p->val;
  read_unlock(&p->lock);

  printk("%s: count %zu pos %lld\n", __func__, count, *f_pos);

  for (i = 0; i < count; i++) {
    if (copy_to_user(&buf[i], &val, 1)) {
      retval = -EFAULT;
      goto out;
    }
  }
  retval = count;
out:
  return (retval);
}

/* 第一引数のstruct inodeは削除 */
static long int devone_ioctl(struct file *filep, unsigned int cmd,
                             unsigned long arg) {

  struct devone_data *dev = filep->private_data;
  struct ioctl_cmd data;
  struct ioctl_cmd __user *uarg = (struct ioctl_cmd __user *)arg;

  if (_IOC_TYPE(cmd) != IOC_MAGIC)
    return -ENOTTY;
  if (_IOC_SIZE(cmd) != sizeof(struct ioctl_cmd))
    return -EINVAL;

  memset(&data, 0, sizeof(data));

  switch (cmd) {
  /* userland write */
  case IOCTL_VALSET:
    if (!capable(CAP_SYS_ADMIN)) {
      return -EPERM;
    }
    /* copy_from_user側でaccess_ok()が呼ばれる */
    if (copy_from_user(&data, uarg, sizeof(data))) {
      return -EFAULT;
    }

    printk("IOCTL_cmd.val %u (%s)\n", data.val, __func__);

    write_lock(&dev->lock);
    dev->val = data.val;
    write_unlock(&dev->lock);
    break;

  /* userland read */
  case IOCTL_VALGET:
    read_lock(&dev->lock);
    data.val = dev->val;
    read_unlock(&dev->lock);

    /* copy_to_user側でaccess_ok()が呼ばれる */
    if (copy_to_user(uarg, &data, sizeof(data))) {
      return -EFAULT;
    }
    break;

  default:
    return -ENOTTY;
    break;
  }

  return 0;
}

struct file_operations devone_fops = {
    .open = devone_open,
    .release = devone_close,
    .write = devone_write,
    .read = devone_read,
    /* .ioctl は削除 */
    .unlocked_ioctl = devone_ioctl,
};

static int __init devone_init(void) {
  dev_t dev = MKDEV(devone_major, devone_minor);
  int ret;

  /* ここでdevが初期化される */
  ret = alloc_chrdev_region(&dev, 0, devone_devs, DRIVER_NAME);
  if (ret)
    return ret;

  devone_major = MAJOR(dev);

  cdev_init(&devone_cdev, &devone_fops);
  devone_cdev.owner = THIS_MODULE;
  devone_cdev.ops = &devone_fops;

  /* class登録 */
  devone_class = class_create(DRIVER_NAME);
  if (IS_ERR(devone_class)) {
    ret = PTR_ERR(devone_class);
    devone_class = NULL;
    goto err_unregister;
  }

  /* class_device_create は削除された */
  devone_device =
      device_create(devone_class, NULL, dev, NULL, "devone%d", devone_minor);
  if (IS_ERR(devone_device)) {
    ret = PTR_ERR(devone_device);
    devone_device = NULL;
    goto err_class;
  }

  ret = cdev_add(&devone_cdev, dev, devone_devs);
  if (ret)
    goto err_device;

  printk(KERN_ALERT "%s: driver(major %d) installed\n", DRIVER_NAME,
         devone_major);
  return 0;

err_device:
  device_destroy(devone_class, dev);
  devone_device = NULL;
err_class:
  class_destroy(devone_class);
  devone_class = NULL;
err_unregister:
  unregister_chrdev_region(dev, devone_devs);

  return ret;
}

static void __exit devone_exit(void) {
  dev_t dev = MKDEV(devone_major, devone_minor);

  /* class登録の解除 */
  if (devone_device) {
    device_destroy(devone_class, dev);
  }
  if (devone_class) {
    class_destroy(devone_class);
  }

  cdev_del(&devone_cdev);
  unregister_chrdev_region(dev, devone_devs);
  printk(KERN_ALERT "%s: driver unloaded\n", DRIVER_NAME);
}

module_init(devone_init);
module_exit(devone_exit);
