/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      hardware test for F(P^2) multiplication
 * 
*/

#include "../../../ref_c/SIKE_vOW_software/src/config.h"
#include "../../../ref_c/SIKE_vOW_software/src/P128/P128_internal.h"
#include "test_extras.h"
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

#include <fp2mul_mont_hw.h> 
#include <Murax.h>

void main() {

  f2elm_t a, b, c, ma, mb, mc;

  digit_t *sub_res = (digit_t*)&(mc[0]);
  digit_t *add_res = (digit_t*)&(mc[1]);

  digit_t *a_0 = (digit_t*)&(ma[0]);
  digit_t *a_1 = (digit_t*)&(ma[1]);

  digit_t *b_0 = (digit_t*)&(mb[0]);
  digit_t *b_1 = (digit_t*)&(mb[1]);
 
  // generate random inputs from F(p^2)
  fp2random128_test((digit_t*)ma); 
  fp2random128_test((digit_t*)ma); 
  fp2random128_test((digit_t*)mb); 
   
  printf("\n");
 
  uint64_t t0 = -cpucycles();
  
  // Montgomery multiplication on F(p^2)
  fp2mul_mont_hw(a_0, a_1, b_0, b_1, mc[0], mc[1]);

  t0 += cpucycles();
 
  printf("\nresult for sub part:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%08x\n", sub_res[i]); 
  }

  printf("\nresult for add part:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%08x\n", add_res[i]); 
  } 
 
  printf("\n------------PERFORMANCE------------\n\n");
  printf("cycles for fp2mul128_mont in hw: %" PRIu64 "\n\n", t0);

}