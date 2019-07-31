//
//  main.m
//  AppTest
//
//  Created by TanHao on 13-10-27.
//  Copyright (c) 2013年 http://www.tanhao.me. All rights reserved.
//
#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>


#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#include "Common.h"

int main(int argc, const char * argv[])
{
    io_iterator_t iterator;
    kern_return_t kr;
    io_object_t   driver;
    
    CFMutableDictionaryRef matchDictionary = IOServiceMatching("IOFramebuffer");
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchDictionary, &iterator);
    if (kr != kIOReturnSuccess)
    {
        return 0;
    }
    
    if ((driver = IOIteratorNext(iterator)) != 0)
    {
        //service表示需要连接的驱动程序
        io_service_t service = driver;
        //task表示当前应用程序
        task_port_t task = mach_task_self();
        //type的含义由开发者选定方式定义(忽略)
        uint32_t type = 0;
        //connect用于保存这个连接
        io_connect_t connect = 0;
        
        
        
        
        
        
  CFMutableDictionaryRef properties = NULL;
        kr = IORegistryEntryCreateCFProperties(service,
                                               &properties,
                                               kCFAllocatorDefault,
                                               kNilOptions);
        if (kr == kIOReturnSuccess)
        {
          // NSLog(@"%@",(__bridge NSDictionary*)properties);
        }
    
        
        
        
         system("kill -9 $(ps -ef|grep WindowServer |awk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ')");
        
        //打开连接
      
        kr=IOServiceOpen(service, task, 0, &connect);
        if(kr!=kIOReturnSuccess)
        puts("xxx");

        uint64_t inputvalue[2];
        //设置参数
        uint32_t inputCount = 2;
    inputvalue[0]=18;
    inputvalue[1]=0;
        size_t inputstructsize = 17*8;
    void* inputStruct=calloc(270,8);
    memset(inputStruct,1,270*8);

    inputvalue[0]=18;
    inputvalue[1]=0;

        IOConnectCallMethod(connect,16,&inputvalue,inputCount, inputStruct,inputstructsize , NULL,NULL,NULL,NULL);
      puts("read");
        //关闭连接
        
        IOServiceClose(service);
        
    }
    
    return 0;
}
