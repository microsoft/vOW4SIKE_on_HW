/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      for the communication with get_4_isog and eval_4_isog hardware modules
 * 
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <get_4_isog_and_eval_4_isog_hw.h>
#include <Murax.h>
#include <sys/stat.h>

volatile int32_t *ctrl_get_4_isog_and_eval_4_isog = (uint32_t*)0xf0050000;

/**
 * \brief            This function communicates with the controller
 * \input            elements from F(p^2): X4, Z4, pts[i], phiP, phiQ, phiR  
 * \output           updated pts[i] and phiP, phiQ, phiR, generated A24 and C24
**/

void get_4_isog_and_eval_4_isog_hw(uint32_t X4_0[],
                                   uint32_t X4_1[],
                                   uint32_t Z4_0[],
                                   uint32_t Z4_1[],
                                   uint32_t X4_pre_0[],
                                   uint32_t X4_pre_1[],
                                   uint32_t Z4_pre_0[],
                                   uint32_t Z4_pre_1[],
                                   uint32_t A24_0[],
                                   uint32_t A24_1[],
                                   uint32_t C24_0[],
                                   uint32_t C24_1[],
                                   bool get_4_isog,
                                   bool first_eval_4_isog,
                                   bool last_eval_4_isog
                                   )
{
  int i;

  volatile uint32_t *element_X4_0 = &ctrl_get_4_isog_and_eval_4_isog[WR_X4_0_BIT];
  volatile uint32_t *element_X4_1 = &ctrl_get_4_isog_and_eval_4_isog[WR_X4_1_BIT];
  volatile uint32_t *element_Z4_0 = &ctrl_get_4_isog_and_eval_4_isog[WR_Z4_0_BIT];
  volatile uint32_t *element_Z4_1 = &ctrl_get_4_isog_and_eval_4_isog[WR_Z4_1_BIT];
  volatile uint32_t *element_A24_0 = &ctrl_get_4_isog_and_eval_4_isog[RD_A24_0_BIT];
  volatile uint32_t *element_A24_1 = &ctrl_get_4_isog_and_eval_4_isog[RD_A24_1_BIT];
  volatile uint32_t *element_C24_0 = &ctrl_get_4_isog_and_eval_4_isog[RD_C24_0_BIT];
  volatile uint32_t *element_C24_1 = &ctrl_get_4_isog_and_eval_4_isog[RD_C24_1_BIT]; 

  // for get_4_isog, here are the steps:
  // 1: send X4 and Z4
  // 2: trigger computation
  // 3: return A24 and C24
  if (get_4_isog) {
    // reset the hardware core and send the COMMAND
    ctrl_get_4_isog_and_eval_4_isog[CONTROL_BIT] = (RESET | (GET_4_ISOG_CMD << 8));

    // send X4 and Z4
    for (i = 0; i < NWORDS; i++) {
      element_X4_0[0] = X4_0[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_X4_1[0] = X4_1[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_Z4_0[0] = Z4_0[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_Z4_1[0] = Z4_1[i];
    }    

    // trigger the computation
    ctrl_get_4_isog_and_eval_4_isog[CONTROL_BIT] = (START | (GET_4_ISOG_CMD << 8)); 

    while ((ctrl_get_4_isog_and_eval_4_isog[GET_4_ISOG_BIT] & 0x00000001) == BUSY);

    // return generated A24 and C24
    for (i = 0; i < NWORDS; i++) {
      A24_0[i] = ctrl_get_4_isog_and_eval_4_isog[RD_A24_0_BIT];
    } 
    
    for (i = 0; i < NWORDS; i++) {
      A24_1[i] = ctrl_get_4_isog_and_eval_4_isog[RD_A24_1_BIT];
    }  

    for (i = 0; i < NWORDS; i++) {
      C24_0[i] = ctrl_get_4_isog_and_eval_4_isog[RD_C24_0_BIT];
    } 
    
    for (i = 0; i < NWORDS; i++) {
      C24_1[i] = ctrl_get_4_isog_and_eval_4_isog[RD_C24_1_BIT];
    }

  }
  // for the very first eval_4_isog, here are the steps:
  // 1: send X4 and Z4
  else if (first_eval_4_isog) {

    // prepare the command for eval_4_isog
    ctrl_get_4_isog_and_eval_4_isog[CONTROL_BIT] = (EVAL_4_ISOG_CMD << 8);

    // send X4 and Z4
    for (i = 0; i < NWORDS; i++) {
      element_X4_0[0] = X4_0[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_X4_1[0] = X4_1[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_Z4_0[0] = Z4_0[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_Z4_1[0] = Z4_1[i];
    }    
  }
  // for the last eval_4_isog, here are the steps:
  // 1: wait for the eval_4_isog_result_ready signal
  // 2: read back results from t10 and t11 and write the results back to X4 and Z4
  else if (last_eval_4_isog) {
    // eval_4_isog_result_ready = 1
    while ((ctrl_get_4_isog_and_eval_4_isog[GET_4_ISOG_BIT] & 0x00010000) != (1 << 16));
    // return t10 and t11 and write them back to X4 and Z4
    for (i = 0; i < NWORDS; i++) {
      X4_pre_0[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T10_0_BIT];
    }  
    for (i = 0; i < NWORDS; i++) {
      X4_pre_1[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T10_1_BIT];
    }    
    for (i = 0; i < NWORDS; i++) {
      Z4_pre_0[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T11_0_BIT];
    }  
    for (i = 0; i < NWORDS; i++) {
      Z4_pre_1[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T11_1_BIT];
    } 
  }
  // for the middle eval_4_isog (not the first nor the last one), here are the steps:
  // 1: wait for the eval_4_isog_XZ_can_overwrite signal
  // 2: send new pair of X4 and Z4
  // 3: wait for the eval_4_isog_result_ready signal
  // 4: return t10 and t11 results and write back to X4 and Z4
  else {
    // eval_4_isog_XZ_can_overwrite = 1
    while ((ctrl_get_4_isog_and_eval_4_isog[GET_4_ISOG_BIT] & 0x00000100) != (1 << 8));

    // send new pair of X4 and Z4 
    for (i = 0; i < NWORDS; i++) {
      element_X4_0[0] = X4_0[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_X4_1[0] = X4_1[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_Z4_0[0] = Z4_0[i];
    }

    for (i = 0; i < NWORDS; i++) {
      element_Z4_1[0] = Z4_1[i];
    } 
    // eval_4_isog_result_ready = 1
    while ((ctrl_get_4_isog_and_eval_4_isog[GET_4_ISOG_BIT] & 0x00010000) != (1 << 16));

    // return t10 and t11 and write them back to X4 and Z4
    for (i = 0; i < NWORDS; i++) {
      X4_pre_0[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T10_0_BIT];
    }  

    for (i = 0; i < NWORDS; i++) {
      X4_pre_1[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T10_1_BIT];
    }    

    for (i = 0; i < NWORDS; i++) {
      Z4_pre_0[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T11_0_BIT];
    }  

    for (i = 0; i < NWORDS; i++) {
      Z4_pre_1[i] = ctrl_get_4_isog_and_eval_4_isog[RD_T11_1_BIT];
    } 
  }
}