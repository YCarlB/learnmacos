# MIG漏洞分析
## MIG
MIG是Mach系统中使用的一种自动生成代码的脚本语言，以.def结尾。通过工具生成的代码分为xxx.h,xxxClient.c和xxxServer.c三个部分，在编译应用层程序时，和xxxClient.c文件一起编译，使用自动生成的代码。这里就是poc中的taskUser.c和task.h。

相关的细节可以查看《Mac OS X Internals: A Systems Approach》一书的Section 9.6中的描述。

### MIG技术简介
MIG是一个工具，可以通过定义文件生成Client-Server形式基于mach IPC的RPC代码（这里mach IPC指使用mach port传递mach msg）
典型的IPC代码需要实现：数据准备、发送、接收、解包、消息复用；MIG自动生成完成这些事情的代码
MIG生成的代码，调用mach ports的各种API
MIG定义文件的扩展名.defs
下面列举MIG实现的一些功能：
clock_priv, clock_reply, exc, host_notify_reply, host_priv, host_security, ledger, mach_exc, mach_host, mach_vm, map, memory_object_default, memory_object_name, notify, processor, processor_set, prof, security, semaphore, sync, task_access, thread_act, vm_map
MIG生成的代码，丰富了接口，提供了更多（ BSD层没有的）功能，非常有用：
比如host相关的API可以获取硬件信息
mach_vm和vm_map相关API提供了虚拟内存操作接口
thread_act相关API提供了thread操作接口
 

## cve-2016-4669 poc分析
poc程序有一个主程序r3gister
然后通过task.defs生成了剩下三个程序用来y通信。

这个漏洞参考
http://turingh.github.io/2016/11/07/CVE-2016-4669%E5%88%86%E6%9E%90%E4%B8%8E%E8%B0%83%E8%AF%95/
```
* thread #19, name = '0xffffff8031e1e748', queue = '0x0', stop reason = EXC_BAD_INSTRUCTION (code=13, subcode=0x0)
  * frame #0: 0xffffff801e792371 kernel.development`hw_lock_to + 17
    frame #1: 0xffffff801e797223 kernel.development`usimple_lock(l=0xdeadbeefdeadbef7) at locks_i386.c:365:5 [opt]
    frame #2: 0xffffff801e677a0c kernel.development`ipc_port_release_send [inlined] lck_spin_lock(lck=0xdeadbeefdeadbef7) at locks_i386.c:269:2 [opt]
    frame #3: 0xffffff801e677a04 kernel.development`ipc_port_release_send(port=0xdeadbeefdeadbeef) at ipc_port.c:1651 [opt]
    frame #4: 0xffffff801e695b63 kernel.development`mach_ports_register(task=<unavailable>, memory=0xffffff802f9fdc10, portsCnt=3) at ipc_tt.c:1097:4 [opt]
    frame #5: 0xffffff801e6efc4f kernel.development`_Xmach_ports_register(InHeadP=0xffffff803ce7e87c, OutHeadP=0xffffff803ce7ed90) at task_server.c:647:18 [opt]

```

程序有问题在mach_ports_register
源码
https://github.com/apple/darwin-xnu/blob/a449c6a3b8014d9406c2ddbdc81795da24aa7443/osfmk/kern/ipc_tt.c
在这里

```
kern_return_t
mach_ports_register(
    task_t            task,
    mach_port_array_t    memory,
    mach_msg_type_number_t    portsCnt)
{
    ipc_port_t ports[TASK_PORT_REGISTER_MAX];
    unsigned int i;

    if ((task == TASK_NULL) ||
        (portsCnt > TASK_PORT_REGISTER_MAX) ||
        (portsCnt && memory == NULL))
        return KERN_INVALID_ARGUMENT;

    /*
     *    Pad the port rights with nulls.
     */

    for (i = 0; i < portsCnt; i++)
        ports[i] = memory[i];
    for (; i < TASK_PORT_REGISTER_MAX; i++)
        ports[i] = IP_NULL;

    itk_lock(task);
    if (task->itk_self == IP_NULL) {
        itk_unlock(task);
        return KERN_INVALID_ARGUMENT;
    }

    /*
     *    Replace the old send rights with the new.
     *    Release the old rights after unlocking.
     */

    for (i = 0; i < TASK_PORT_REGISTER_MAX; i++) {
        ipc_port_t old;

        old = task->itk_registered[i];
        task->itk_registered[i] = ports[i];
        ports[i] = old;
    }

    itk_unlock(task);

    for (i = 0; i < TASK_PORT_REGISTER_MAX; i++)
        if (IP_VALID(ports[i]))
            ipc_port_release_send(ports[i]);
            ///就是这个释放崩溃，因为这个大小是我们指定的，所以我们可以将大于的长度从memcpy放入ports从而造成溢出

    /*
     *    Now that the operation is known to be successful,
     *    we can free the memory.
     */

    if (portsCnt != 0)
        kfree(memory,
              (vm_size_t) (portsCnt * sizeof(mach_port_t)));
        //这个数值有问题，3我们给他的
    return KERN_SUCCESS;
}

/*
 *    Routine:    mach_ports_lookup [kernel call]
 *    Purpose:
 *        Retrieves (clones) the stashed port send rights.
 *    Conditions:
 *        Nothing locked.  If successful, the caller gets
 *        rights and memory.
 *    Returns:
 *        KERN_SUCCESS        Retrieved the send rights.
 *        KERN_INVALID_ARGUMENT    The task is null.
 *        KERN_INVALID_ARGUMENT    The task is dead.
 *        KERN_RESOURCE_SHORTAGE    Couldn't allocate memory.
 */


```

```
    typedef struct {
        mach_msg_header_t Head;
        /* start of the kernel processed data */
        mach_msg_body_t msgh_body;
        mach_msg_ool_ports_descriptor_t init_port_set;
        /* end of the kernel processed data */
        NDR_record_t NDR;
        mach_msg_type_number_t init_port_setCnt;
        mach_msg_trailer_t trailer;
    } Request __attribute__((unused));
```
这里大小已经有了，但是下面用的却是用户给的，所以造成了释放范围错误
所以造成漏洞




## 查看堆块所在的zone的小技巧

```


用zfree函数的流程中会出现相关的转换代码。


if (zone->use_page_list) {
        struct zone_page_metadata *page_meta = get_zone_page_metadata((struct zone_free_element *)addr);

其实就是get_zone_page_metadata这个函数的实现了，这里的addr就是memory。

1
(lldb) p *(zone_page_metadata*)0xffffff80140e7000
(zone_page_metadata) $1 = {
  pages = {
    next = 0xffffff8012db4000
    prev = 0xffffff801109f000
  }
  elements = 0xffffff80140e76d0
  zone = 0xffffff800f480ba0
  alloc_count = 12
  free_count = 1
}
在查看zone的具体数据，可以得知memory被分配在哪个zone当中。

1
...
zone_name = 0xffffff8009d35bac "kalloc.16"
...



用zfree函数的流程中会出现相关的转换代码。

if (zone->use_page_list) {
        struct zone_page_metadata *page_meta = get_zone_page_metadata((struct zone_free_element *)addr);
        if (zone != page_meta->zone) {

其实就是get_zone_page_metadata这个函数的实现了，这里的addr就是memory。


(lldb) p *(zone_page_metadata*)0xffffff80140e7000
(zone_page_metadata) $1 = {
  pages = {
    next = 0xffffff8012db4000
    prev = 0xffffff801109f000
  }
  elements = 0xffffff80140e76d0
  zone = 0xffffff800f480ba0
  alloc_count = 12
  free_count = 1
}
在查看zone的具体数据，可以得知memory被分配在哪个zone当中。


zone_name = 0xffffff8009d35bac "kalloc.16"

```
