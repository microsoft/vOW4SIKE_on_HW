/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      for the communication with F(p^2) multiplier
 * 
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <fp2mul_mont_hw.h>
#include <Murax.h>
#include <sys/stat.h>

#ifdef CONTROLLER_HARDWARE
volatile int32_t *ctrl_fp2_mul = (uint32_t*)0xf0050000;
#else
volatile int32_t *ctrl_fp2_mul = (uint32_t*)0xf0030000;
#endif

/**
 * \brief            This function communicates with the Montgomery_multiplier hardware module
 * \input            two elements from F(p^2): a=a0+i*a1, b=b0+i*b1 
 * \output           c = a*b = c0+i*c1
**/

// NWORDS
// #define CONTROL_BIT 1 // address offset = 4
// #define BUSY 1
// #define RESET 2
// #define START 1
// #define A_0_BIT 2
// #define A_1_BIT 3
// #define B_0_BIT 4
// #define B_1_BIT 5
// #define C_1_BIT 6
// #define AB_0_LEFT_BIT  2 // index = 2*i
// #define AB_0_RIGHT_BIT 3 // index = 2*i+1
// #define AB_0_LEFT_BIT  4 // index = 2*i
// #define AB_0_RIGHT_BIT 5 // index = 2*i+1

// FIXME: Current version talks to Apb3 module supporting RADIX=32 only

void fp2mul_mont_hw(uint32_t a0[],
                    uint32_t a1[],
                    uint32_t b0[],
                    uint32_t b1[],
                    uint32_t c0[],
                    uint32_t c1[])
{

  int i;

  volatile uint32_t *element_a0 = &ctrl_fp2_mul[A_0_BIT];
  volatile uint32_t *element_a1 = &ctrl_fp2_mul[A_1_BIT];
  volatile uint32_t *element_b0 = &ctrl_fp2_mul[B_0_BIT];
  volatile uint32_t *element_b1 = &ctrl_fp2_mul[B_1_BIT]; 

  // reset the hardware core
  ctrl_fp2_mul[CONTROL_BIT] = (RESET << 2);

  // send a0
  for (i = 0; i < NWORDS; i++) {
    element_a0[0] = a0[i];
  }

  // send a1
  for (i = 0; i < NWORDS; i++) {
    element_a1[0] = a1[i];
  }

  // send b0
  for (i = 0; i < NWORDS; i++) {
    element_b0[0] = b0[i];
  }

  // send b1
  for (i = 0; i < NWORDS; i++) {
    element_b1[0] = b1[i];
  }

  // start the hardware core
  ctrl_fp2_mul[CONTROL_BIT] = (START << 2);

  // hw core running/busy
  while ((ctrl_fp2_mul[CONTROL_BIT] & 0x00000001) == BUSY);
  
  // return c0
  for (i = 0; i < (NWORDS/2); i++) {
    c0[2*i] = ctrl_fp2_mul[AB_0_LEFT_BIT];
    c0[2*i+1] = ctrl_fp2_mul[AB_0_RIGHT_BIT];
  }

  // return c1
  for (i = 0; i < (NWORDS/2); i++) {
    c1[2*i] = ctrl_fp2_mul[AB_1_LEFT_BIT];
    c1[2*i+1] = ctrl_fp2_mul[AB_1_RIGHT_BIT];
  }

}