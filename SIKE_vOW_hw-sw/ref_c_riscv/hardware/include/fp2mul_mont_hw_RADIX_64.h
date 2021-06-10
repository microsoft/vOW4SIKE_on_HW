/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      header file for fp2mul_mont_hw_RADIX_64.c
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
#define A_0_BIT 2
#define A_1_BIT 3
#define B_0_BIT 4
#define B_1_BIT 5
#define C_1_BIT 6
// AB_0 = {AB_0_3_BIT, AB_0_2_BIT, AB_0_1_BIT, AB_0_0_BIT}
#define AB_0_3_BIT  4  
#define AB_0_2_BIT  5   
#define AB_0_1_BIT  6  
#define AB_0_0_BIT  7
// AB_1 = {AB_1_3_BIT, AB_1_2_BIT, AB_1_1_BIT, AB_1_0_BIT}
#define AB_1_3_BIT  8  
#define AB_1_2_BIT  9   
#define AB_1_1_BIT  10  
#define AB_1_0_BIT  11

#if defined(P377)
    #define NWORDS 6
#elif defined(P434)
    #define NWORDS 7
#elif defined(P503)
    #define NWORDS 8
#elif defined(P610)
    #define NWORDS 10
#else // p751
    #define NWORDS 12
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