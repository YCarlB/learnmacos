# ool堆喷

## ool四种descriptor结构




typedef struct
{
​	natural_t					pad1;
​	mach_msg_size_t				pad2;
​	unsigned int				pad3 : 24;
​	mach_msg_descriptor_type_t	type : 8;
} mach_msg_type_descriptor_t;

typedef struct
{
​	mach_port_t					name;
​	// Pad to 8 bytes everywhere except the K64 kernel where mach_port_t is 8 bytes 	
​	mach_msg_size_t				pad1;
​	unsigned int				pad2 : 16;
​	mach_msg_type_name_t		disposition : 8;
​	mach_msg_descriptor_type_t	type : 8;
} mach_msg_port_descriptor_t;

typedef struct
{
​	void*						address;
​	#if !defined(__LP64__) 
​	mach_msg_size_t				size;
​	#endif 
​	boolean_t					deallocate: 8;
​	mach_msg_copy_options_t		copy: 8;
​	unsigned int				pad1: 8;
​	mach_msg_descriptor_type_t	type: 8;
​	#if defined(__LP64__) 
​	mach_msg_size_t				size;
​	#endif 
} mach_msg_ool_descriptor_t;

typedef struct
{
​	void*						address;
​	#if !defined(__LP64__) 
​	mach_msg_size_t				count;
​	#endif 
​	boolean_t					deallocate: 8;
​	mach_msg_copy_options_t		copy: 8;
​	mach_msg_type_name_t		disposition : 8;
​	mach_msg_descriptor_type_t	type : 8;
​	#if defined(__LP64__) 
​	mach_msg_size_t				count;
​	#endif 
} mach_msg_ool_ports_descriptor_t;

## 漏洞分析

数据被存放在kmalloc中

这个中断把size的地址当作了size的内容，从而导致长度溢出。

这里有个问题，这个漏洞必须使用makefile
他的size地址当作size，所以size必须小于0x4000000（development和ios有这个问题）
https://googleprojectzero.blogspot.com/2017/04/exception-oriented-exploitation-on-ios.html

## 漏洞流程

1.首先因为内核使用了许久，所以先通过ool消息申请大量chunk让地址连续

​	为了能在同一个zone里面，所以大小要和利用的消息一样大

2.然后为了能够利用连续的地址，释放中间的一部分。

​	没必要一定全释放掉，但是少了可能被系统抢占。
3.申请一半作为消息（可省）
4.申请新的一个内存作为利用
5.找到这个端口

6.mach_voucher_extract_attr_recipe_args  堆溢出

​	申请massage在堆上

​	第一个指针address指向port指针的数组。

​	更改他指向用户态





7.设置虚假的port和task
然后调用clock_sleep_trap猜测地址

8.然后调用pid_for_task获取内存内容猜测内核地址

9.然后调用pid_for_task 指向allproc 里面存着的所有进程信息

allproc指向proc的pid
pid_for_task获取程序pid
然后proc-0x10是下一个的指针

10.然后用kerneltask里面的数据调用task_get_speacial_pot来提升端口权限，然后调用
mach_vm_read_overwrite
mach_vm_write
读写任意内存



### 参考

https://www.anquanke.com/post/id/86977
https://theori.io/research/korean/osx-kernel-exploit-2
https://gentle-knife.github.io/2019/02/26/mach_msg%E8%AF%A6%E8%A7%A3/

exp：堆喷exp文件夹