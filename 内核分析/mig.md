# MIG
## 描述
MIG是Mach系统中使用的一种自动生成代码的脚本语言，以.def结尾。通过工具生成的代码分为xxx.h,xxxClient.c和xxxServer.c三个部分，在编译应用层程序时，和xxxClient.c文件一起编译，使用自动生成的代码。这里就是poc中的taskUser.c和task.h。

相关的细节可以查看《Mac OS X Internals: A Systems Approach》一书的Section 9.6中的描述。
## 使用
首先找到内核的task.defs
然后输入mig task.defs
生成三个文件


task.h
需要包涵的程序头

taskServer.c内核服务代码

taskUser.c需要使用的用户客户端代码


然后通过

    clang -o r3gister r3gister.c taskUser.c
编译
就可以使用mig了




