/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      header file for fp2mul_mont_hw.c
 * 
*/
  
#ifndef FP2_MUL_MONT_HW_H
#define FP2_MUL_MONT_HW_H

#include <stddef.h>
#include <stdint.h>

#define CONTROL_BIT 1 // address offset = 4
#define BUSY 1
#define RESET 1
#define START 2
#define A_0_BIT 4
#define A_1_BIT 5
#define B_0_BIT 6
#define B_1_BIT 7 
#define AB_0_LEFT_BIT  28 // index = 2*i
#define AB_0_RIGHT_BIT 29 // index = 2*i+1
#define AB_1_LEFT_BIT  30 // index = 2*i
#define AB_1_RIGHT_BIT 31 // index = 2*i+1

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
 * \brief            This function communicates with the Montgomery_multiplier hardware module
 * \input            two elements from F(p^2): a=a0+i*a1, b=b0+i*b1 
 * \output           ab = a*b = ab0+i*ab1
**/

void fp2mul_mont_hw(uint32_t a0[],
                    uint32_t a1[],
                    uint32_t b0[],
                    uint32_t b1[],
                    uint32_t c0[],
                    uint32_t c1[]);

#endif 