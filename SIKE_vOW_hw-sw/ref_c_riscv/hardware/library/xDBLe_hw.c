/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      for the communication with xDBL hardware module
 * 
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <xDBLe_hw.h>
#include <Murax.h>
#include <sys/stat.h>

volatile int32_t *ctrl_xDBLe = (uint32_t*)0xf0050000;

/**
 * \brief            This function communicates with the controller
 * \input            four elements from F(p^2): X, Z, A24, C24 
 * \output           updated X and Z
**/

void xDBLe_hw(uint32_t XP_0[],
              uint32_t XP_1[],
              uint32_t ZP_0[],
              uint32_t ZP_1[],
              uint32_t XQ_0[],
              uint32_t XQ_1[],
              uint32_t ZQ_0[],
              uint32_t ZQ_1[],
              uint32_t A24_0[],
              uint32_t A24_1[],
              uint32_t C24_0[],
              uint32_t C24_1[],
              uint32_t LOOP
             )
{
  int i;

  volatile uint32_t *element_X_0 = &ctrl_xDBLe[WR_X_0_BIT];
  volatile uint32_t *element_X_1 = &ctrl_xDBLe[WR_X_1_BIT];
  volatile uint32_t *element_Z_0 = &ctrl_xDBLe[WR_Z_0_BIT];
  volatile uint32_t *element_Z_1 = &ctrl_xDBLe[WR_Z_1_BIT];
  volatile uint32_t *element_A24_0 = &ctrl_xDBLe[WR_A24_0_BIT];
  volatile uint32_t *element_A24_1 = &ctrl_xDBLe[WR_A24_1_BIT];
  volatile uint32_t *element_C24_0 = &ctrl_xDBLe[WR_C24_0_BIT];
  volatile uint32_t *element_C24_1 = &ctrl_xDBLe[WR_C24_1_BIT];

  // reset the hardware core and send the COMMAND
  ctrl_xDBLe[CONTROL_BIT] = (RESET | (XDBLE_CMD << 8));

  // send X and Z
  for (i = 0; i < NWORDS; i++) {
    element_X_0[0] = XP_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_X_1[0] = XP_1[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_Z_0[0] = ZP_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_Z_1[0] = ZP_1[i];
  }

  // send A24 and C24
  for (i = 0; i < NWORDS; i++) {
    element_A24_0[0] = A24_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_A24_1[0] = A24_1[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_C24_0[0] = C24_0[i];
  }

  for (i = 0; i < NWORDS; i++) {
    element_C24_1[0] = C24_1[i];
  }

  // set xDBLe_NUM_LOOPS
  ctrl_xDBLe[LOOP_BIT] = LOOP;

  // trigger the computation
  ctrl_xDBLe[CONTROL_BIT] = (START | (XDBLE_CMD << 8));

  // hw core running/busy
  while ((ctrl_xDBLe[CONTROL_BIT] & 0x00000001) == BUSY);

  // return updated X and Z
  for (i = 0; i < NWORDS; i++) {
    XQ_0[i] = ctrl_xDBLe[RD_X_0_BIT];
  }

  for (i = 0; i < NWORDS; i++) {
    XQ_1[i] = ctrl_xDBLe[RD_X_1_BIT];
  }

  for (i = 0; i < NWORDS; i++) {
    ZQ_0[i] = ctrl_xDBLe[RD_Z_0_BIT];
  }

  for (i = 0; i < NWORDS; i++) {
    ZQ_1[i] = ctrl_xDBLe[RD_Z_1_BIT];
  }
}