/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      for the communication with xADD hardware module
 * 
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <xADD_loop_hw.h>
#include <Murax.h>
#include <sys/stat.h>

volatile int32_t *ctrl_xADD_loop = (uint32_t*)0xf0050000;

/**
 * \brief            This function communicates with the controller
 * \input            elements from F(p^2): P[array], Q, PQ
 * \output           updated Q, and PQ
**/

// load data as secret key to sk memory
void secret_key_load(uint32_t sk[], int sk_words)
{
  int i;

  volatile uint32_t *element_sk = &ctrl_xADD_loop[WR_SK_BIT];

  // reset the hardware core and send the COMMAND
  ctrl_xADD_loop[CONTROL_BIT] = (RESET | (XADD_LOOP_CMD << 8)); 

  // load the secret key
  for (i = 0; i < sk_words; i++) {
    element_sk[0] = sk[i];
  }

}

void xADD_hw(uint32_t XP_0[],
             uint32_t XP_1[],
             uint32_t ZP_0[],
             uint32_t ZP_1[],
             uint32_t XQ_0[],
             uint32_t XQ_1[],
             uint32_t ZQ_0[],
             uint32_t ZQ_1[],
             uint32_t XPQ_0[],
             uint32_t XPQ_1[],
             uint32_t ZPQ_0[],
             uint32_t ZPQ_1[], 
             int start_index,
             int end_index,
             int first_xADD,
             int last_xADD
             )
{
  int i;
 
  volatile uint32_t *element_XP_0 = &ctrl_xADD_loop[WR_XP_0_BIT];
  volatile uint32_t *element_XP_1 = &ctrl_xADD_loop[WR_XP_1_BIT];
  volatile uint32_t *element_ZP_0 = &ctrl_xADD_loop[WR_ZP_0_BIT];
  volatile uint32_t *element_ZP_1 = &ctrl_xADD_loop[WR_ZP_1_BIT];
  volatile uint32_t *element_XQ_0 = &ctrl_xADD_loop[WR_XQ_0_BIT];
  volatile uint32_t *element_XQ_1 = &ctrl_xADD_loop[WR_XQ_1_BIT];
  volatile uint32_t *element_ZQ_0 = &ctrl_xADD_loop[WR_ZQ_0_BIT];
  volatile uint32_t *element_ZQ_1 = &ctrl_xADD_loop[WR_ZQ_1_BIT]; 
  volatile uint32_t *element_XPQ_0 = &ctrl_xADD_loop[WR_XPQ_0_BIT];
  volatile uint32_t *element_XPQ_1 = &ctrl_xADD_loop[WR_XPQ_1_BIT];
  volatile uint32_t *element_ZPQ_0 = &ctrl_xADD_loop[WR_ZPQ_0_BIT];
  volatile uint32_t *element_ZPQ_1 = &ctrl_xADD_loop[WR_ZPQ_1_BIT]; 

// first call of xADD
if (first_xADD) {
  // reset the hardware core and send the COMMAND
  ctrl_xADD_loop[CONTROL_BIT] = (RESET | (XADD_LOOP_CMD << 8));

  // send the start and end indices
  ctrl_xADD_loop[INDEX_BIT] = ((end_index << 16) | start_index);

  // send P, Q, PQ 
    // P
  for (i = 0; i < NWORDS; i++) {
    element_XP_0[0] = XP_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_XP_1[0] = XP_1[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZP_0[0] = ZP_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZP_1[0] = ZP_1[i];
  }
    // Q
  for (i = 0; i < NWORDS; i++) {
    element_XQ_0[0] = XQ_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_XQ_1[0] = XQ_1[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZQ_0[0] = ZQ_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZQ_1[0] = ZQ_1[i];
  }
    // PQ 
  for (i = 0; i < NWORDS; i++) {
    element_XPQ_0[0] = XPQ_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_XPQ_1[0] = XPQ_1[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZPQ_0[0] = ZPQ_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZPQ_1[0] = ZPQ_1[i];
  }

  // trigger the computation
  ctrl_xADD_loop[CONTROL_BIT] = (START | (XADD_LOOP_CMD << 8));
}

else {
// wait for the xADD_P_can_overwrite signal
  while ((ctrl_xADD_loop[CONTROL_BIT] >> 8) != 1);  
    
 // send P  
    // P
  for (i = 0; i < NWORDS; i++) {
    element_XP_0[0] = XP_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_XP_1[0] = XP_1[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZP_0[0] = ZP_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_ZP_1[0] = ZP_1[i];
  }
}

if (last_xADD) {

  // hw core running/busy
  while ((ctrl_xADD_loop[CONTROL_BIT] & 0x00000001) == BUSY);

  // return updated Q, and PQ 
    // Q
  for (i = 0; i < NWORDS; i++) {
    XQ_0[i] = ctrl_xADD_loop[RD_XQ_0_BIT];
  }
  for (i = 0; i < NWORDS; i++) {
    XQ_1[i] = ctrl_xADD_loop[RD_XQ_1_BIT];
  }
  for (i = 0; i < NWORDS; i++) {
    ZQ_0[i] = ctrl_xADD_loop[RD_ZQ_0_BIT];
  }
  for (i = 0; i < NWORDS; i++) {
    ZQ_1[i] = ctrl_xADD_loop[RD_ZQ_1_BIT];
  }
    // PQ
  for (i = 0; i < NWORDS; i++) {
    XPQ_0[i] = ctrl_xADD_loop[RD_XPQ_0_BIT];
  }
  for (i = 0; i < NWORDS; i++) {
    XPQ_1[i] = ctrl_xADD_loop[RD_XPQ_1_BIT];
  }
  for (i = 0; i < NWORDS; i++) {
    ZPQ_0[i] = ctrl_xADD_loop[RD_ZPQ_0_BIT];
  }
  for (i = 0; i < NWORDS; i++) {
    ZPQ_1[i] = ctrl_xADD_loop[RD_ZPQ_1_BIT];
  }
}
  // computation done  
}

