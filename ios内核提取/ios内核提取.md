# ios10 内核提取

## ios10以后对内核不加密
## 下载
越狱ios安装ssh
/System/Library/Caches/com.apple.kernelcaches/kernelcache内核目录
scp下载到mac本地
## 解压
http://newosxbook.com/tools/joker.html
到上面的网址下载joker

然后执行
./joker.universal  -dec kernelcache
内核会被解压到/tmp/kernel

## http://www.ios-download.com/index.php?page=download&id=3086
