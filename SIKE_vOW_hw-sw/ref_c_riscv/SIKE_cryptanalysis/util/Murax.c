#include <stdio.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
#include "murax.h"
#pragma GCC diagnostic pop



#define csr_read(csr)                             \
  ({                                              \
       register unsigned long __v;                \
       __asm__ __volatile__ ("csrr %0, " #csr     \
                             : "=r" (__v));       \
       __v;                                       \
   })

uint64_t cpucycles(void)
{
  uint64_t lo = csr_read(mcycle);
  uint64_t hi = csr_read(mcycleh);
  return (hi << 32 ) | lo;
}

void init_uart()
{
  // clok_divider = Fclk / baudrate / rxSamplePerBit
// UART->CLOCK_DIVIDER = 45000000 / 9600 / 5;
#ifdef DE1_SoC
  UART->CLOCK_DIVIDER = 45000000 / 9600 / 5;
#elif SIM
  UART->CLOCK_DIVIDER = 10000000 / 9600 / 5;
#endif
}


extern uint32_t _stack_start;
extern uint32_t _stack_end;

extern uint32_t _heap_start;
extern uint32_t _heap_end;


void spray_mem()
{
  uint32_t* p;
  uint32_t marker = 0;

  for (p = &_heap_start; p <= &marker; p++)
   *p = 0xabcdabcd;
}

void report_mem()
{
  uint32_t heap = 0;
  uint32_t* p = &_heap_start;

  while (*(p++) != 0xabcdabcd)
    heap += 1;

  while (*(p++) == 0xabcdabcd);

  printf("\nheap usage: %i\nstack usage: %i\n\n", heap, &_stack_start - p);
}

