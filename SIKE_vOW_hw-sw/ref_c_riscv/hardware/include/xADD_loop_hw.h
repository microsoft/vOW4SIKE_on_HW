/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      header file for xADD_loop_hw.c
 * 
*/

#ifndef XADD_LOOP_HW_H
#define XADD_LOOP_HW_H

#include <stddef.h>
#include <stdint.h>

#define CONTROL_BIT    1
#define INDEX_BIT      3 
#define WR_XP_0_BIT   12
#define WR_XP_1_BIT   13
#define WR_ZP_0_BIT   14
#define WR_ZP_1_BIT   15
#define WR_XQ_0_BIT   16
#define WR_XQ_1_BIT   17
#define WR_ZQ_0_BIT   18
#define WR_ZQ_1_BIT   19
#define WR_XPQ_0_BIT  20
#define WR_XPQ_1_BIT  21
#define WR_ZPQ_0_BIT  22
#define WR_ZPQ_1_BIT  23
#define WR_SK_BIT     28
 
#define RD_XQ_0_BIT   16
#define RD_XQ_1_BIT   17
#define RD_ZQ_0_BIT   18
#define RD_ZQ_1_BIT   19
#define RD_XPQ_0_BIT  20
#define RD_XPQ_1_BIT  21
#define RD_ZPQ_0_BIT  22
#define RD_ZPQ_1_BIT  23

#define XADD_LOOP_CMD 4
#define BUSY 1
#define RESET 1
#define START 2

#if defined(P128)
  #define NWORDS 4
  #define SKWORDS 94 // FIXME
#elif defined(P377)
  #define NWORDS 12
  #define SKWORDS 82 // FIXME
#elif defined(P434)
  #define NWORDS 14
  #define SKWORDS 94
#elif defined(P503)
  #define NWORDS 16
  #define SKWORDS 109
#elif defined(P610)
  #define NWORDS 20
  #define SKWORDS 131
#else // p751
  #define NWORDS 24
  #define SKWORDS 161
#endif


/**
 * \brief            This function communicates with the controller
 * \input            elements from F(p^2): P[array], Q, PQ
 * \output           updated Q, and PQ
**/


void secret_key_load(uint32_t sk[], int sk_words);
 
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
             );

#endif