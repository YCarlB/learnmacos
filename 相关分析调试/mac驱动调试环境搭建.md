                       # 调试环境搭建

## 下载安装

1.首先下载vmware mac版，内核镜像，然后安装。



2.对应版本kdk（kernel debug kit）

kdk是给mac调试提供的组件，如果没有这个，就没有相应的调试符号了。

https://developer.apple.com/download/more/?q=Kernel%20Debug%20Kit（kdk链接）

这里说一下，kdk要和自己的内核版本对上号

不知道自己内核什么版本，执行如下命令



```
sw_vers | grep BuildVersion



```



然后在安装好的虚拟机内外安装 kdk,安装好之后在虚拟机里面执行如下命令，将development版本复制到文件（开发版本与发布版本不太一样，为了利用漏洞，还是不要进行这一步了）。

```
sudo cp /Library/Developer/KDKs/KDK_10.12.6_16G29.kdk/System/Library/Kernels/kernel.development /System/Library/Kernels/



```

3.配置调试参数

```
sudo nvram boot-args="debug=0x145 kext-dev-mode=1 kcsuffix=development pmuflags=1 -v"

boot-args：系统的启动参数
debug=0×141，表示系统可以进行远程链接调试(0x141为开机调试，0x144是nmi中断调试)
kext-dev-mode=1允许加载未签名kext
kcsuffix=development 允许我们启动系统，通过development，与之前我们copy到/Systems/Library/Kernel下的kernel.development对应，如果我们之前拷贝的是kernel.debug，那么这里填kcsuffic=debug
pmuflags=1关闭定时器
-v显示内核加载信息.
```



然后再清除kext缓存

```
sudo kextcache -invalidate /



如果没有这一步，内核不会更改，

```

4.配置lldb
​	$lldb里面输入

```
target create /Library/Developer/KDKs/KDK_10.12.2_16C67.kdk/System/Library/Kernels/kernel.development
```

然后会出现错误，依照错误提示执行两个命令

>

command script import "/Library/Developer/KDKs/KDK_10.12.2_16C67.kdk/System/Library/Kernels/kernel.development.dSYM/Contents/Resources/DWARF/../Python/lldbmacros/xnu.py"

退出lldb
echo “settings set target.load-script-from-symbol-file true” > ~/.lldbinit
再次进入lldb





5.虚拟机里面输入nvram -p查看参数是否设置成功

然后重启虚拟机（这里一定要重启，我关机再开了好几次没反应，气死了）





出现debug wait后在lldb中输入kdp-remote  192.168.31.128

如果要在运行的时候进行断点，需要按住com+alt+control+shift+fn
然后按下esc



help可以看到命令

​	showallkmods是看驱动的
​	另外，对于voltron与zprint之间貌似存在冲突不能同时使用，很难受

​	虚拟机里面sysctl machdep.cpu|grep SMAP查看smap

6.恢复内核

```
删除以下内容/System/Library/
	Kernels/kernel.development
	PrelinkedKernels/prelinkedkernel.development
	Caches/com.apple.kext.caches/Startup/kernelcache.development
让缓存失效
sudo kextcache -i /
```

​	
## 双机调试
### 远程

sudo nvram boot-args="debug=0x8146 kdp_match_name=firewire fwkdp=0x8000 fwdebug=0x40 pmuflags=1 -v"

### 本机
开fwkdp -v
kdb 127.0.0.1




### ref
https://4hou.win/wordpress/?p=27434
