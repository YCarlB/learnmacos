#include <stdio.h>

extern "C" {
#include "iosurface.h"
#include "parameters.h"
#include "kernel_memory.h"
}

#include "exploit.h"

/*
1. Cleanup header imports, delete unused files/functions
2. Check file headers
3. Release...
*/

int main(int argc, char *argv[]) {

  if (!parameters_init()) {
    printf("failed to initialized parameters\n");
    return 0;
  }

  Exploit exploit;
  if (!exploit.GetKernelTaskPort()) {
    printf("Exploit failed\n");
  } else {
    printf("Exploit succeeded\n");
  }

}
