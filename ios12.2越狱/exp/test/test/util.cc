// <3 nedwill 2019
#include "util.h"
#include "parameters.h"

#include <stdio.h>

#define VM_MIN_KERNEL_ADDRESS 0xffffff8000000000ULL
#define VM_MAX_KERNEL_ADDRESS 0xfffffff3ffffffffULL

bool LooksLikeKaddr(uint64_t addr) {
  // This is a freed chunk. Don't touch it!
  if ((addr & 0xFFFFFFFF) == 0xDEADBEEF) {
    return false;
  }

  if (addr < VM_MIN_KERNEL_ADDRESS) {
    return false;
  }

  if (addr > VM_MAX_KERNEL_ADDRESS) {
    return false;
  }

  return true;
}
