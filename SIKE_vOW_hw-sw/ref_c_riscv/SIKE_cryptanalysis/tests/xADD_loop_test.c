/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      software test for xADD loop function
 * 
*/
   
#include "../../../ref_c/SIKE_vOW_software/src/config.h"
#include "../../../ref_c/SIKE_vOW_software/src/curve_math.h"
#include "../../../ref_c/SIKE_vOW_software/src/P128/P128_internal.h" 
#include "../../../ref_c/SIKE_vOW_software/src/random/random.h"
#include "test_extras.h"
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>  

#ifndef x86
#include <Murax.h>
#endif

#define SKWORDS 94
#define NBITS 3 


void main() {
  f2elm_t A24;
  point_proj_t P_0, P_1, P_2, P_3, Q, PQ;
  unsigned char m[SKWORDS << 2];

  // generate random binary sequence as secret key
  randombytes(m, (SKWORDS << 2));
  randombytes(m, (SKWORDS << 2)); 

  printf("\nfirst byte of message m is %u\n", m[0]);

  // generate random inputs

  digit_t *XQ_0 = (digit_t*)&((Q->X)[0]); 
  digit_t *XQ_1 = (digit_t*)&((Q->X)[1]);
  digit_t *ZQ_0 = (digit_t*)&((Q->Z)[0]); 
  digit_t *ZQ_1 = (digit_t*)&((Q->Z)[1]);
  digit_t *XPQ_0 = (digit_t*)&((PQ->X)[0]); 
  digit_t *XPQ_1 = (digit_t*)&((PQ->X)[1]);
  digit_t *ZPQ_0 = (digit_t*)&((PQ->Z)[0]); 
  digit_t *ZPQ_1 = (digit_t*)&((PQ->Z)[1]); 

  digit_t *XP_0_0 = (digit_t*)&((P_0->X)[0]); 
  digit_t *XP_1_0 = (digit_t*)&((P_0->X)[1]);
  digit_t *ZP_0_0 = (digit_t*)&((P_0->Z)[0]); 
  digit_t *ZP_1_0 = (digit_t*)&((P_0->Z)[1]);

  digit_t *XP_0_1 = (digit_t*)&((P_1->X)[0]); 
  digit_t *XP_1_1 = (digit_t*)&((P_1->X)[1]);
  digit_t *ZP_0_1 = (digit_t*)&((P_1->Z)[0]); 
  digit_t *ZP_1_1 = (digit_t*)&((P_1->Z)[1]);

  digit_t *XP_0_2 = (digit_t*)&((P_2->X)[0]); 
  digit_t *XP_1_2 = (digit_t*)&((P_2->X)[1]);
  digit_t *ZP_0_2 = (digit_t*)&((P_2->Z)[0]); 
  digit_t *ZP_1_2 = (digit_t*)&((P_2->Z)[1]);

  digit_t *XP_0_3 = (digit_t*)&((P_3->X)[0]); 
  digit_t *XP_1_3 = (digit_t*)&((P_3->X)[1]);
  digit_t *ZP_0_3 = (digit_t*)&((P_3->Z)[0]); 
  digit_t *ZP_1_3 = (digit_t*)&((P_3->Z)[1]);
 
  fp2random128_test((digit_t*)(P_0->X)); 
  fp2random128_test((digit_t*)(P_0->Z));
  fp2random128_test((digit_t*)(P_1->X)); 
  fp2random128_test((digit_t*)(P_1->Z));
  fp2random128_test((digit_t*)(P_2->X)); 
  fp2random128_test((digit_t*)(P_2->Z));
  fp2random128_test((digit_t*)(P_3->X)); 
  fp2random128_test((digit_t*)(P_3->Z));

  fp2random128_test((digit_t*)(Q->X)); 
  fp2random128_test((digit_t*)(Q->Z));
  fp2random128_test((digit_t*)(PQ->X)); 
  fp2random128_test((digit_t*)(PQ->Z));

 
  printf("\ninput XP_0_3:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XP_0_3[i]); 
  }

  printf("\ninput XP_1_3:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XP_1_3[i]);  
  }

  printf("\ninput ZP_0_3:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZP_0_3[i]); 
  }

  printf("\ninput ZP_1_3:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZP_1_3[i]);  
  }

  uint64_t t0 = -cpucycles();
  
  // Computation
  // Main loop
  int k = 1;

  if (((m[k >> 3] >> (k & 0x07)) & 1) == 0) {
    xADD(Q, P_0, PQ->X);
    fp2mul128_mont(Q->X, PQ->Z, Q->X);    /* serial */ 
  } else {
    xADD(PQ, P_0, Q->X);
    fp2mul128_mont(PQ->X, Q->Z, PQ->X);     /* serial */ 
  }

  k++;
  
  if (((m[k >> 3] >> (k & 7)) & 1) == 0) {
    xADD(Q, P_1, PQ->X);
    fp2mul128_mont(Q->X, PQ->Z, Q->X);    /* serial */ 
  } else {
    xADD(PQ, P_1, Q->X);
    fp2mul128_mont(PQ->X, Q->Z, PQ->X);     /* serial */ 
  }
 
  k++;
  
  if (((m[k >> 3] >> (k & 7)) & 1) == 0) {
    xADD(Q, P_3, PQ->X);
    fp2mul128_mont(Q->X, PQ->Z, Q->X);    /* serial */ 
  } else {
    xADD(PQ, P_3, Q->X);
    fp2mul128_mont(PQ->X, Q->Z, PQ->X);     /* serial */ 
  }  

  t0 += cpucycles();

  // modular correction to reduce to range [0, p128-1] 
  fpcorrection128(XQ_0);
  fpcorrection128(XQ_1);
  fpcorrection128(ZQ_0);
  fpcorrection128(ZQ_1);
  fpcorrection128(XPQ_0);
  fpcorrection128(XPQ_1);
  fpcorrection128(ZPQ_0);
  fpcorrection128(ZPQ_1);
 

  printf("\nresult XQ_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XQ_0[i]); 
  }

  printf("\nresult XQ_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XQ_1[i]);  
  }

  printf("\nresult ZQ_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZQ_0[i]); 
  }

  printf("\nresult ZQ_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZQ_1[i]);  
  }

  printf("\nresult XPQ_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPQ_0[i]); 
  }

  printf("\nresult XPQ_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPQ_1[i]);  
  }

  printf("\nresult ZPQ_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPQ_0[i]); 
  }

  printf("\nresult ZPQ_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPQ_1[i]);  
  }

  printf("\n------------PERFORMANCE------------\n\n");
  printf("cycles for xADD in sw: %" PRIu64 "\n\n", t0);  

}

   
 

 
 