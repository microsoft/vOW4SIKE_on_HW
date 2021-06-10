/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      for the communication with F(p^2) multiplier (RADIX=64)
 * 
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <fp2mul_mont_hw_RADIX_64.h> 
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
  uint32_t temp;

  // reset the hardware core
  ctrl_fp2_mul[CONTROL_BIT] = (RESET << 2);

  // send a0
  for (i = 0; i < 2*NWORDS; i++) {
    element_a0[0] = a0[i];
  }

  // send a1
  for (i = 0; i < 2*NWORDS; i++) {
    element_a1[0] = a1[i];
  }

  // send b0
  for (i = 0; i < 2*NWORDS; i++) {
    element_b0[0] = b0[i];
  }

  // send b1
  for (i = 0; i < 2*NWORDS; i++) {
    element_b1[0] = b1[i];
  }

  // start the hardware core
  ctrl_fp2_mul[CONTROL_BIT] = (START << 2);

  // hw core running/busy
  while (ctrl_fp2_mul[CONTROL_BIT] == BUSY);
  
  // return c0
  // for (i = 0; i < ((NWORDS+1)/2); i++) {
  //   c0[4*i]   = ctrl_fp2_mul[AB_0_3_BIT];
  //   c0[4*i+1] = ctrl_fp2_mul[AB_0_2_BIT];
  //   c0[4*i+2] = ctrl_fp2_mul[AB_0_1_BIT];
  //   c0[4*i+3] = ctrl_fp2_mul[AB_0_0_BIT];
  // }

  // // return c1
  // for (i = 0; i < ((NWORDS+1)/2); i++) {
  //   c1[4*i]   = ctrl_fp2_mul[AB_1_3_BIT];
  //   c1[4*i+1] = ctrl_fp2_mul[AB_1_2_BIT];
  //   c1[4*i+2] = ctrl_fp2_mul[AB_1_1_BIT];
  //   c1[4*i+3] = ctrl_fp2_mul[AB_1_0_BIT];
  // } 

// specific for p434
    c0[0] = ctrl_fp2_mul[AB_0_3_BIT];
    c0[1] = ctrl_fp2_mul[AB_0_2_BIT];
    c0[2] = ctrl_fp2_mul[AB_0_1_BIT];
    c0[3] = ctrl_fp2_mul[AB_0_0_BIT];

    c0[4] = ctrl_fp2_mul[AB_0_3_BIT];
    c0[5] = ctrl_fp2_mul[AB_0_2_BIT];
    c0[6] = ctrl_fp2_mul[AB_0_1_BIT];
    c0[7] = ctrl_fp2_mul[AB_0_0_BIT];

    c0[8] = ctrl_fp2_mul[AB_0_3_BIT];
    c0[9] = ctrl_fp2_mul[AB_0_2_BIT];
    c0[10] = ctrl_fp2_mul[AB_0_1_BIT];
    c0[11] = ctrl_fp2_mul[AB_0_0_BIT];

    c0[12] = ctrl_fp2_mul[AB_0_3_BIT];
    c0[13] = ctrl_fp2_mul[AB_0_2_BIT];
    temp = ctrl_fp2_mul[AB_0_1_BIT];
    temp = ctrl_fp2_mul[AB_0_0_BIT];

    c1[0] = ctrl_fp2_mul[AB_1_3_BIT];
    c1[1] = ctrl_fp2_mul[AB_1_2_BIT];
    c1[2] = ctrl_fp2_mul[AB_1_1_BIT];
    c1[3] = ctrl_fp2_mul[AB_1_0_BIT];

    c1[4] = ctrl_fp2_mul[AB_1_3_BIT];
    c1[5] = ctrl_fp2_mul[AB_1_2_BIT];
    c1[6] = ctrl_fp2_mul[AB_1_1_BIT];
    c1[7] = ctrl_fp2_mul[AB_1_0_BIT];

    c1[8] = ctrl_fp2_mul[AB_1_3_BIT];
    c1[9] = ctrl_fp2_mul[AB_1_2_BIT];
    c1[10] = ctrl_fp2_mul[AB_1_1_BIT];
    c1[11] = ctrl_fp2_mul[AB_1_0_BIT];
    
    c1[12] = ctrl_fp2_mul[AB_1_3_BIT];
    c1[13] = ctrl_fp2_mul[AB_1_2_BIT];
    temp = ctrl_fp2_mul[AB_1_1_BIT];
    temp = ctrl_fp2_mul[AB_1_0_BIT];
}