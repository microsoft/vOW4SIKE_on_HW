/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      header file for xDBLe_hw.c
 * 
*/

#ifndef XDBLE_HW_H
#define XDBLE_HW_H

#include <stddef.h>
#include <stdint.h>

#define CONTROL_BIT 1
#define LOOP_BIT    2
#define WR_X_0_BIT  4 
#define WR_X_1_BIT  5
#define WR_Z_0_BIT  6
#define WR_Z_1_BIT  7
#define WR_A24_0_BIT   8
#define WR_A24_1_BIT   9
#define WR_C24_0_BIT  10
#define WR_C24_1_BIT  11

#define RD_X_0_BIT  4
#define RD_X_1_BIT  5
#define RD_Z_0_BIT  6
#define RD_Z_1_BIT  7

#define XDBLE_CMD 1
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
             );

#endif