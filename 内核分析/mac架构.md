# mac架构分析



## mac接口结构

### mach层接口

最底层的接口，但是官方不太喜欢让人用。

### Bsd层接口

推荐的接口

### iokit

​	一个基于c++的驱动，可以通过建立userclinet来进行通信。



每个用户连接建立一个userclient，userclient也是驱动，是可以和用户通信的驱动。然后每个设备声明一个实例化的对象来进行控制。

## ipc结构

ipc port 是mac的内核通信结构，进程线程对应的管理全交给他来负责。

ipc port 等同于ipc object



进程结构task指向ipc space

ipc space指向entry

entry存着指向port的指针

port在port

这几个每一个都有一个zone

### task

proc指向task

proc指向cred

cred里面存在poscred管理权限。

allporc指向一个porc的双向链表



参考

http://turingh.github.io/2017/01/10/CVE-2016-7637-%E5%86%8D%E8%B0%88Mach-IPC/

  https://www.cnblogs.com/andypeker/p/4360540.html

http://turingh.github.io/2017/01/10/CVE-2016-7637-%E5%86%8D%E8%B0%88Mach-IPC/

  https://turingh.github.io/2016/07/05/%E5%86%8D%E7%9C%8BCVE-2016-1757%E6%B5%85%E6%9E%90mach%20message%E7%9A%84%E4%BD%BF%E7%94%A8/