struct route_in6 {
    /*
     * N.B: struct route_in6 must begin with ro_{rt,srcia,flags}
     * because the code does some casts of a 'struct route_in6 *'
     * to a 'struct route *'.
     */
    struct rtentry    *ro_rt;
    struct  llentry *ro_lle;
    struct ifaddr    *ro_srcia;
    uint32_t    ro_flags;    /* route flags */
    struct sockaddr_in6 ro_dst;
};

struct    ip6po_nhinfo {
    struct    sockaddr *ip6po_nhi_nexthop;
    struct    route_in6 ip6po_nhi_route; /* Route to the nexthop */
};
struct    ip6po_rhinfo {
    struct    ip6_rthdr *ip6po_rhi_rthdr; /* Routing header */
    struct    route_in6 ip6po_rhi_route; /* Route to the 1st hop */
};
struct  ip6_pktopts {
         struct  mbuf *ip6po_m;  /* Pointer to mbuf storing the data */
         int     ip6po_hlim;     /* Hoplimit for outgoing packets */
 
         /* Outgoing IF/address information */
         struct  in6_pktinfo *ip6po_pktinfo;
 
         /* Next-hop address information */
         struct  ip6po_nhinfo ip6po_nhinfo;
 
         struct  ip6_hbh *ip6po_hbh; /* Hop-by-Hop options header */
 
         /* Destination options header (before a routing header) */
         struct  ip6_dest *ip6po_dest1;
 
         /* Routing header related info. */
         struct  ip6po_rhinfo ip6po_rhinfo;
 
         /* Destination options header (after a routing header) */
         struct  ip6_dest *ip6po_dest2;
 
         int     ip6po_tclass;   /* traffic class */
 
         int     ip6po_minmtu;  /* fragment vs PMTU discovery policy */
 #define IP6PO_MINMTU_MCASTONLY  -1 /* default; send at min MTU for multicast*/
 #define IP6PO_MINMTU_DISABLE     0 /* always perform pmtu disc */
 #define IP6PO_MINMTU_ALL         1 /* always send at min MTU */
 
         int     ip6po_prefer_tempaddr;  /* whether temporary addresses are
                                            preferred as source address */
 #define IP6PO_TEMPADDR_SYSTEM   -1 /* follow the system default */
 #define IP6PO_TEMPADDR_NOTPREFER 0 /* not prefer temporary address */
 #define IP6PO_TEMPADDR_PREFER    1 /* prefer temporary address */
 
         int ip6po_flags;
 #if 0   /* parameters in this block is obsolete. do not reuse the values. */
 #define IP6PO_REACHCONF 0x01    /* upper-layer reachability confirmation. */
 #define IP6PO_MINMTU    0x02    /* use minimum MTU (IPV6_USE_MIN_MTU) */
 #endif
 #define IP6PO_DONTFRAG  0x04    /* disable fragmentation (IPV6_DONTFRAG) */
 #define IP6PO_USECOA    0x08    /* use care of address */
 };
