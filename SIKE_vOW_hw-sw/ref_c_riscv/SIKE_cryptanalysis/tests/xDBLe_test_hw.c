/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      hardware test for xDBL loop function
 * 
*/

#include "../../../ref_c/SIKE_vOW_software/src/config.h"
#include "../../../ref_c/SIKE_vOW_software/src/P128/P128_internal.h" 
#include "test_extras.h"
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h> 

#include <xDBLe_hw.h>
#include <Murax.h>

void main () {
  f2elm_t A24, C24;
  point_proj_t P;

  digit_t *A24_0 = (digit_t*)&(A24[0]);
  digit_t *A24_1 = (digit_t*)&(A24[1]);
  digit_t *C24_0 = (digit_t*)&(C24[0]);
  digit_t *C24_1 = (digit_t*)&(C24[1]);
  digit_t *XP_0 = (digit_t*)&((P->X)[0]); 
  digit_t *XP_1 = (digit_t*)&((P->X)[1]);
  digit_t *ZP_0 = (digit_t*)&((P->Z)[0]); 
  digit_t *ZP_1 = (digit_t*)&((P->Z)[1]);

  fp2random128_test((digit_t*)A24); 
  fp2random128_test((digit_t*)C24);
  fp2random128_test((digit_t*)(P->X)); 
  fp2random128_test((digit_t*)(P->Z));

  uint64_t t0 = -cpucycles();

  xDBLe_hw(XP_0, XP_1, ZP_0, ZP_1, XP_0, XP_1, ZP_0, ZP_1, A24_0, A24_1, C24_0, C24_1, 4);

  t0 += cpucycles();

  // modular correction to reduce to range [0, p128-1]
  fpcorrection128(XP_0);
  fpcorrection128(XP_1);
  fpcorrection128(ZP_0);
  fpcorrection128(ZP_1);

  printf("\nresult XP_0:\n");

  for (int i=0; i<NWORDS; i++) {
    printf("%d    ", i); 
    printf("%x\n", XP_0[i]); 
  }

  printf("\nresult XP_1:\n");

  for (int i=0; i<NWORDS; i++) {
    printf("%d    ", i); 
    printf("%x\n", XP_1[i]); 
  }

  printf("\nresult ZP_0:\n");

  for (int i=0; i<NWORDS; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZP_0[i]);
  }

  printf("\nresult ZP_1:\n");

  for (int i=0; i<NWORDS; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZP_1[i]);
  }

  printf("\n------------PERFORMANCE------------\n\n");
  printf("cycles for xDBLe in hw: %" PRIu64 "\n\n", t0);      
}