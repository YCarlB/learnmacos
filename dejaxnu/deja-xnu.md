# project zero deja-xnu

## 链接
https://googleprojectzero.blogspot.com/2018/10/deja-xnu.html

## IODataQueue


### 盘古的旧漏洞

链接 http://blog.pangu.io/cve-2014-4461/
```
Boolean IOSharedDataQueue::initWithCapacity(UInt32 size)
{
...

allocSize = round_page(size + DATA_QUEUE_MEMORY_HEADER_SIZE + DATA_QUEUE_MEMORY_APPENDIX_SIZE);

if (allocSize < size) {
return false;
}

// 分配足够大小的内存给dataQueue
dataQueue = (IODataQueueMemory *)IOMallocAligned(allocSize, PAGE_SIZE);
if (dataQueue == 0) {
return false;
}

...

// notifyMsg成员被放在dataQueue的尾部
appendix            = (IODataQueueAppendix *)((UInt8 *)dataQueue + size + DATA_QUEUE_MEMORY_HEADER_SIZE);
appendix->version   = 0;
notifyMsg           = &(appendix->msgh);
setNotificationPort(MACH_PORT_NULL);

return true;
}
```
分配的时候分配了size + DATA_QUEUE_MEMORY_HEADER_SIZE + DATA_QUEUE_MEMORY_APPENDIX_SIZE
并且在里面放了一个port
返回的时候
```
IOMemoryDescriptor *IOSharedDataQueue::getMemoryDescriptor()
{
IOMemoryDescriptor *descriptor = 0;

if (dataQueue != 0) {
descriptor = IOMemoryDescriptor::withAddress(dataQueue, getQueueSize() + DATA_QUEUE_MEMORY_HEADER_SIZE + DATA_QUEUE_MEMORY_APPENDIX_SIZE, kIODirectionOutIn);
}

return descriptor;
}
```
返回了全部内容，所以用户可以控制内核的port



而IODataQueue是他的父类
```
class IODataQueue : public OSObject
{
OSDeclareDefaultStructors(IODataQueue)
protected:
IODataQueueMemory * dataQueue;
void * notifyMsg;
public:
static IODataQueue *withCapacity(UInt32 size);
static IODataQueue *withEntries(UInt32 numEntries, UInt32 entrySize);
virtual Boolean initWithCapacity(UInt32 size);
virtual Boolean initWithEntries(UInt32 numEntries, UInt32 entrySize);
virtual Boolean enqueue(void *data, UInt32 dataSize);
virtual void setNotificationPort(mach_port_t port);
virtual IOMemoryDescriptor *getMemoryDescriptor();
};
```
同样存了用户的数据和内核的端口。

结构路径
https://github.com/apple/darwin-xnu/blob/0a798f6738bc1db01281fc08ae024145e84df927/iokit/IOKit/IODataQueue.h
存在六个漏洞



## 触发结构体的条件
通过查找iokit触发



 I/O Kit framework一个提供给iokit的接口
这个函数将数据写入共享用户IODataQueueEnqueue
同样存在漏洞类似于内核share，存了一个port
```
IODataQueueEnqueue(IODataQueueMemory *dataQueue, void *data, uint32_t dataSize)
{
UInt32              head        = dataQueue->head;  // volatile
UInt32              tail        = dataQueue->tail;
UInt32              queueSize   = dataQueue->queueSize;
UInt32              entrySize   = dataSize + DATA_QUEUE_ENTRY_HEADER_SIZE;
IOReturn            retVal      = kIOReturnSuccess;
IODataQueueEntry *  entry;

if ( tail >= head )
{
// Is there enough room at the end for the entry?
if ( (tail + entrySize) <= queueSize )
{
entry = (IODataQueueEntry *)((UInt8 *)dataQueue->queue + tail);

memcpy(&(entry->data), data, dataSize);

entry->size = dataSize;            

// The tail can be out of bound when the size of the new entry
// exactly matches the available space at the end of the queue.
// The tail can range from 0 to queueSize inclusive.

dataQueue->tail += entrySize;
}
else if ( head > entrySize )     // Is there enough room at the beginning?
{
entry = (IODataQueueEntry *)((UInt8 *)dataQueue->queue);
memcpy(&(entry->data), data, dataSize);

// Wrap around to the beginning, but do not allow the tail to catch
// up to the head.

entry->size = dataSize;

// We need to make sure that there is enough room to set the size before
// doing this. The user client checks for this and will look for the size
// at the beginning if there isn't room for it at the end.

if ( ( queueSize - tail ) >= DATA_QUEUE_ENTRY_HEADER_SIZE )
{
((IODataQueueEntry *)((UInt8 *)dataQueue->queue + tail))->size = dataSize;
}

dataQueue->tail = entrySize;
}
else
{
retVal = kIOReturnOverrun;  // queue is full
}
}
else
{
// Do not allow the tail to catch up to the head when the queue is full.
// That's why the comparison uses a '>' rather than '>='.

if ( (head - tail) > entrySize )
{
entry = (IODataQueueEntry *)((UInt8 *)dataQueue->queue + tail);

memcpy(&(entry->data), data, dataSize);

entry->size = dataSize;
dataQueue->tail += entrySize;
}
else
{
retVal = kIOReturnOverrun;  // queue is full
}
}

// Send notification (via mach message) that data is available.    

if ( retVal == kIOReturnSuccess ) {
if ( ( head == tail )               /* queue was empty prior to enqueue() */
||   ( dataQueue->head == tail ) )  /* queue was emptied during enqueue() */
{
retVal = _IODataQueueSendDataAvailableNotification(dataQueue);
}
}

else if ( retVal == kIOReturnOverrun ) {
// Send extra data available notification, this will fail and we will
// get a send possible notification when the client starts responding
(void) _IODataQueueSendDataAvailableNotification(dataQueue);
}

return retVal;
}

```
## 漏洞分析 
```
OSDefineMetaClassAndStructors(IODataQueue, OSObject)

IODataQueue *IODataQueue::withCapacity(UInt32 size)
{
IODataQueue *dataQueue = new IODataQueue;

if (dataQueue) {
if (!dataQueue->initWithCapacity(size)) {
dataQueue->release();
dataQueue = 0;
}
}

return dataQueue;
}

IODataQueue *IODataQueue::withEntries(UInt32 numEntries, UInt32 entrySize)
{
IODataQueue *dataQueue = new IODataQueue;

if (dataQueue) {
if (!dataQueue->initWithEntries(numEntries, entrySize)) {
dataQueue->release();
dataQueue = 0;
}
}

return dataQueue;
}

Boolean IODataQueue::initWithCapacity(UInt32 size)
{
vm_size_t allocSize = 0;

if (!super::init()) {
return false;
}

allocSize = round_page(size + DATA_QUEUE_MEMORY_HEADER_SIZE);

if (allocSize < size) {
return false;
}

dataQueue = (IODataQueueMemory *)IOMallocAligned(allocSize, PAGE_SIZE);
if (dataQueue == 0) {
return false;
}

dataQueue->queueSize    = size;
dataQueue->head         = 0;
dataQueue->tail         = 0;

return true;
}

Boolean IODataQueue::initWithEntries(UInt32 numEntries, UInt32 entrySize)
{
return (initWithCapacity((numEntries + 1) * (DATA_QUEUE_ENTRY_HEADER_SIZE + entrySize)));
}
//这里存在数据溢出
void IODataQueue::free()
{
if (dataQueue) {
IOFreeAligned(dataQueue, round_page(dataQueue->queueSize + DATA_QUEUE_MEMORY_HEADER_SIZE));
//这里大小用户控制，并且存在溢出
}

super::free();

return;
}

Boolean IODataQueue::enqueue(void * data, UInt32 dataSize)
{
const UInt32       head = dataQueue->head;  // volatile
const UInt32       tail = dataQueue->tail;
const UInt32       entrySize = dataSize + DATA_QUEUE_ENTRY_HEADER_SIZE;//这里存在数字溢出
IODataQueueEntry * entry;

if ( tail >= head )
{
// Is there enough room at the end for the entry?
if ( (tail + entrySize) <= dataQueue->queueSize )//这里存在数字溢出 后面的变量也是用户控制的
{
entry = (IODataQueueEntry *)((UInt8 *)dataQueue->queue + tail);

entry->size = dataSize;
memcpy(&entry->data, data, dataSize);
//前面溢出了，这里就溢出了
// The tail can be out of bound when the size of the new entry
// exactly matches the available space at the end of the queue.
// The tail can range from 0 to dataQueue->queueSize inclusive.

dataQueue->tail += entrySize;
}
else if ( head > entrySize ) // Is there enough room at the beginning?
{
// Wrap around to the beginning, but do not allow the tail to catch
// up to the head.

dataQueue->queue->size = dataSize;

// We need to make sure that there is enough room to set the size before
// doing this. The user client checks for this and will look for the size
// at the beginning if there isn't room for it at the end.

if ( ( dataQueue->queueSize - tail ) >= DATA_QUEUE_ENTRY_HEADER_SIZE )
{
((IODataQueueEntry *)((UInt8 *)dataQueue->queue + tail))->size = dataSize;
}

memcpy(&dataQueue->queue->data, data, dataSize);
dataQueue->tail = entrySize;
}
else
{
return false; // queue is full
}
}
else
{
// Do not allow the tail to catch up to the head when the queue is full.
// That's why the comparison uses a '>' rather than '>='.

if ( (head - tail) > entrySize )
{
entry = (IODataQueueEntry *)((UInt8 *)dataQueue->queue + tail);

entry->size = dataSize;
memcpy(&entry->data, data, dataSize);
dataQueue->tail += entrySize;
}
else
{
return false; // queue is full
}
}

// Send notification (via mach message) that data is available.

if ( ( head == tail )                /* queue was empty prior to enqueue() */
|| ( dataQueue->head == tail ) )   /* queue was emptied during enqueue() */
{
sendDataAvailableNotification();
}

return true;
}

void IODataQueue::setNotificationPort(mach_port_t port)
{
static struct _notifyMsg init_msg = { {
MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, 0),
sizeof (struct _notifyMsg),
MACH_PORT_NULL,
MACH_PORT_NULL,
0,
0
} };

if (notifyMsg == 0) {
notifyMsg = IOMalloc(sizeof(struct _notifyMsg));
}

*((struct _notifyMsg *)notifyMsg) = init_msg;

((struct _notifyMsg *)notifyMsg)->h.msgh_remote_port = port;
}

void IODataQueue::sendDataAvailableNotification()
{
kern_return_t kr;
mach_msg_header_t * msgh;

msgh = (mach_msg_header_t *)notifyMsg;
if (msgh && msgh->msgh_remote_port) {
kr = mach_msg_send_from_kernel_proper(msgh, msgh->msgh_size);
switch(kr) {
case MACH_SEND_TIMED_OUT: // Notification already sent
case MACH_MSG_SUCCESS:
break;
default:
IOLog("%s: dataAvailableNotification failed - msg_send returned: %d\n", /*getName()*/"IODataQueue", kr);
break;
}
}
}

IOMemoryDescriptor *IODataQueue::getMemoryDescriptor()
{
IOMemoryDescriptor *descriptor = 0;

if (dataQueue != 0) {
descriptor = IOMemoryDescriptor::withAddress(dataQueue, dataQueue->queueSize + DATA_QUEUE_MEMORY_HEADER_SIZE, kIODirectionOutIn);
}

return descriptor;
}

```


