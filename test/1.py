#!/usr/bin/python
# -*- coding: UTF-8 -*-

# 打开一个文件
f = open("kernel.development", "rb")
s=f.read()

# 关闭打开的文件
f.close()


for i in range(0 ,len(s)):

    if(s[i]=='\x50' and s[i+1]=='\x5c'):
        print hex(i)
