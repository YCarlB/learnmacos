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
然后通过task.defs生成了剩下三个程序用来y通信，另外重写了mach_ports_register函数。

这个漏洞参考
http://turingh.github.io/2016/11/07/CVE-2016-4669%E5%88%86%E6%9E%90%E4%B8%8E%E8%B0%83%E8%AF%95/
