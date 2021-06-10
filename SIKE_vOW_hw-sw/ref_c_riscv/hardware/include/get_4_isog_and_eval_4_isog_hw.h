/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      header file for get_4_isog_and_eval_4_isog_hw.c
 * 
*/

#ifndef GET_4_ISOG_AND_EVAL_4_ISOG_HW_H
#define GET_4_ISOG_AND_EVAL_4_ISOG_HW_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define CONTROL_BIT  1 
#define GET_4_ISOG_BIT  2
#define WR_X4_0_BIT 24 
#define WR_X4_1_BIT 25
#define WR_Z4_0_BIT 26
#define WR_Z4_1_BIT 27

#define RD_A24_0_BIT   8
#define RD_A24_1_BIT   9
#define RD_C24_0_BIT  10
#define RD_C24_1_BIT  11
#define RD_T10_0_BIT  24
#define RD_T10_1_BIT  25
#define RD_T11_0_BIT  26
#define RD_T11_1_BIT  27

#define GET_4_ISOG_CMD 2
#define EVAL_4_ISOG_CMD 3
#define BUSY 1
#define RESET 1
#define START 2


#if defined(P128)
  #define NWORDS 4
#elif defined(P377)
  #define NWORDS 12
#elif defined(P434)
  #define NWORDS 14
#elif defined(P503)
  #define NWORDS 16
#elif defined(P610)
  #define NWORDS 20
#else // p751
  #define NWORDS 24
#endif

/**
 * \brief            This function communicates with the controller
 * \input            elements from F(p^2): X4, Z4, pts[i], phiP, phiQ, phiR, keygen 
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
                                   );

#endif