#include <linux/init.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/list.h>

struct sample_data {
  spinlock_t lock;
  struct file *file;
  struct list_head list;
  wait_queue_head_t wait;
  int no;
};

static int __init list_init(void)
{
  struct sample_data *p;
  pr_info("linked_list: loaded\n");

  
  return 0;
}

static void __exit list_exit(void)
{
  pr_info("linked_list unloaded\n");
}

module_init(list_init);
module_exit(list_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("ymgyt");
MODULE_DESCRIPTION("hello module");
