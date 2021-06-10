/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      software test for F(P^2) multiplication
 * 
*/
 
#include "../../../ref_c/SIKE_vOW_software/src/config.h"
#include "../../../ref_c/SIKE_vOW_software/src/P128/P128_internal.h" 
#include "test_extras.h"
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h> 

#ifndef x86
#include <Murax.h>
#endif

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
  
  #ifdef x86
  FILE * fp_a_0;
  FILE * fp_a_1;
  FILE * fp_b_0;
  FILE * fp_b_1;

  fp_a_0 = fopen ("mem_0_a_0.txt", "w+");
  fp_a_1 = fopen ("mem_0_a_1.txt", "w+");
  fp_b_0 = fopen ("mem_0_b_0.txt", "w+");
  fp_b_1 = fopen ("mem_0_b_1.txt", "w+");

  for (int i=0; i<NWORDS_FIELD; i++) {
    fprintf(fp_a_0, "%08x\n", a_0[i]);
    fprintf(fp_a_1, "%08x\n", a_1[i]);
    fprintf(fp_b_0, "%08x\n", b_0[i]);
    fprintf(fp_b_1, "%08x\n", b_1[i]);
  }

  fclose(fp_a_0);
  fclose(fp_a_1);
  fclose(fp_b_0);
  fclose(fp_b_1);
  #endif


  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%08x\n", a_0[i]); 
  }

  printf("\n");
   
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%08x\n", a_1[i]); 
  }

  printf("\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%08x\n", b_0[i]); 
  }

  printf("\n");
 
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%08x\n", b_1[i]); 
  }


  printf("\n");
 
  uint64_t t0 = -cpucycles();
  
  // Montgomery multiplication on F(p^2)
  fp2mul128_mont(ma, mb, mc); 

  t0 += cpucycles();

  // modular correction to reduce c1 in [0, 2*p128-1] to [0, p128-1]
  fpcorrection128(sub_res);
  fpcorrection128(add_res);
 

  printf("\n");
  
  #ifdef x86
  FILE * fp_sub_res;
  FILE * fp_add_res;
  
  fp_sub_res = fopen ("mult_sub_res_C.txt", "w+");
  fp_add_res = fopen ("mult_add_res_C.txt", "w+");

  for (int i=0; i<NWORDS_FIELD; i++) { 
    fprintf(fp_sub_res, "%08x\n", sub_res[i]);
    fprintf(fp_add_res, "%08x\n", add_res[i]); 
  }
  
  fclose(fp_sub_res);
  fclose(fp_add_res);
  #endif
   
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
  printf("cycles for fp2mul128_mont in sw: %" PRIu64 "\n\n", t0);

}
