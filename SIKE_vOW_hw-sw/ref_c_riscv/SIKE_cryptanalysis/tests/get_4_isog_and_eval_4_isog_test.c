/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      software test for get_4_isog and eval_4_isog function
 * 
*/
 
#include "../../../ref_c/SIKE_vOW_software/src/config.h"
#include "../../../ref_c/SIKE_vOW_software/src/P128/P128_internal.h" 
#include "test_extras.h"
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h> 
#include <stdbool.h>

#ifndef x86
#include <Murax.h>
#endif

#define TESTS 4

void main() {

  int i;
  
  point_proj_t pts[4], R, phiP, phiQ, phiR; 
  f2elm_t A24, C24, coeff[3];

  digit_t *A24_0 = (digit_t*)&(A24[0]);
  digit_t *A24_1 = (digit_t*)&(A24[1]);
  digit_t *C24_0 = (digit_t*)&(C24[0]);
  digit_t *C24_1 = (digit_t*)&(C24[1]);
 
  // generate random input R, pts[], phiP/Q/R
  digit_t *XPTS_0_0 = (digit_t*)&((pts[0]->X)[0]);
  digit_t *XPTS_0_1 = (digit_t*)&((pts[0]->X)[1]);
  digit_t *ZPTS_0_0 = (digit_t*)&((pts[0]->Z)[0]);
  digit_t *ZPTS_0_1 = (digit_t*)&((pts[0]->Z)[1]);
  digit_t *XPTS_1_0 = (digit_t*)&((pts[1]->X)[0]);
  digit_t *XPTS_1_1 = (digit_t*)&((pts[1]->X)[1]);
  digit_t *ZPTS_1_0 = (digit_t*)&((pts[1]->Z)[0]);
  digit_t *ZPTS_1_1 = (digit_t*)&((pts[1]->Z)[1]);
  digit_t *XPTS_2_0 = (digit_t*)&((pts[2]->X)[0]);
  digit_t *XPTS_2_1 = (digit_t*)&((pts[2]->X)[1]);
  digit_t *ZPTS_2_0 = (digit_t*)&((pts[2]->Z)[0]);
  digit_t *ZPTS_2_1 = (digit_t*)&((pts[2]->Z)[1]);
  digit_t *XPTS_3_0 = (digit_t*)&((pts[3]->X)[0]);
  digit_t *XPTS_3_1 = (digit_t*)&((pts[3]->X)[1]);
  digit_t *ZPTS_3_0 = (digit_t*)&((pts[3]->Z)[0]);
  digit_t *ZPTS_3_1 = (digit_t*)&((pts[3]->Z)[1]);

  digit_t *XR_0 = (digit_t*)&((R->X)[0]);
  digit_t *XR_1 = (digit_t*)&((R->X)[1]);
  digit_t *ZR_0 = (digit_t*)&((R->Z)[0]);
  digit_t *ZR_1 = (digit_t*)&((R->Z)[1]);

  digit_t *XphiP_0 = (digit_t*)&((phiP->X)[0]);
  digit_t *XphiP_1 = (digit_t*)&((phiP->X)[1]);
  digit_t *ZphiP_0 = (digit_t*)&((phiP->Z)[0]);
  digit_t *ZphiP_1 = (digit_t*)&((phiP->Z)[1]);

  digit_t *XphiQ_0 = (digit_t*)&((phiQ->X)[0]);
  digit_t *XphiQ_1 = (digit_t*)&((phiQ->X)[1]);
  digit_t *ZphiQ_0 = (digit_t*)&((phiQ->Z)[0]);
  digit_t *ZphiQ_1 = (digit_t*)&((phiQ->Z)[1]);

  digit_t *XphiR_0 = (digit_t*)&((phiR->X)[0]);
  digit_t *XphiR_1 = (digit_t*)&((phiR->X)[1]);
  digit_t *ZphiR_0 = (digit_t*)&((phiR->Z)[0]);
  digit_t *ZphiR_1 = (digit_t*)&((phiR->Z)[1]);  


  // initialize pts[4] randomly
  fp2random128_test((digit_t*)(pts[0]->X));
  fp2random128_test((digit_t*)(pts[0]->Z)); 
  fp2random128_test((digit_t*)(pts[1]->X));
  fp2random128_test((digit_t*)(pts[1]->Z));
  fp2random128_test((digit_t*)(pts[2]->X));
  fp2random128_test((digit_t*)(pts[2]->Z)); 
  fp2random128_test((digit_t*)(pts[3]->X));
  fp2random128_test((digit_t*)(pts[3]->Z));

  // initialize R randomly
  fp2random128_test((digit_t*)(R->X)); 
  fp2random128_test((digit_t*)(R->Z));
  
  // initialize phiP/Q/R randomly
  fp2random128_test((digit_t*)(phiP->X)); 
  fp2random128_test((digit_t*)(phiP->Z));
  fp2random128_test((digit_t*)(phiQ->X)); 
  fp2random128_test((digit_t*)(phiQ->Z));
  fp2random128_test((digit_t*)(phiR->X)); 
  fp2random128_test((digit_t*)(phiR->Z));


  printf("\ninput XR_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XR_0[i]); 
  }
  printf("\ninput XR_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XR_1[i]); 
  }
  printf("\ninput ZR_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZR_0[i]); 
  }
  printf("\ninput ZR_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZR_1[i]); 
  }

  printf("\ninput XPTS_0_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_0_0[i]); 
  }
  printf("\ninput XPTS_0_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_0_1[i]); 
  }
  printf("\ninput ZPTS_0_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_0_0[i]); 
  }
  printf("\ninput ZPTS_0_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_0_1[i]); 
  }

  printf("\ninput XPTS_1_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_1_0[i]); 
  }
  printf("\ninput XPTS_1_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_1_1[i]); 
  }
  printf("\ninput ZPTS_1_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_1_0[i]); 
  }
  printf("\ninput ZPTS_1_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_1_1[i]); 
  }

  printf("\ninput XPTS_2_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_2_0[i]); 
  }
  printf("\ninput XPTS_2_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_2_1[i]); 
  }
  printf("\ninput ZPTS_2_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_2_0[i]); 
  }
  printf("\ninput ZPTS_2_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_2_1[i]); 
  }

  printf("\ninput XPTS_3_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_3_0[i]); 
  }
  printf("\ninput XPTS_3_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_3_1[i]); 
  }
  printf("\ninput ZPTS_3_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_3_0[i]); 
  }
  printf("\ninput ZPTS_3_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_3_1[i]); 
  }

  printf("\ninput XphiP_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiP_0[i]); 
  }
  printf("\ninput XphiP_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiP_1[i]); 
  }
  printf("\ninput ZphiP_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiP_0[i]); 
  }
  printf("\ninput ZphiP_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiP_1[i]); 
  }

  printf("\ninput XphiQ_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiQ_0[i]); 
  }
  printf("\ninput XphiQ_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiQ_1[i]); 
  }
  printf("\ninput ZphiQ_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiQ_0[i]); 
  }
  printf("\ninput ZphiQ_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiQ_1[i]); 
  }

  printf("\ninput XphiR_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiR_0[i]); 
  }
  printf("\ninput XphiR_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiR_1[i]); 
  }
  printf("\ninput ZphiR_0:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiR_0[i]); 
  }
  printf("\ninput ZphiR_1:\n");
  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiR_1[i]); 
  }
 
  uint64_t t0 = -cpucycles();

  // start get_4_isog computation
  get_4_isog(R, A24, C24, coeff);
  
  // start a sequence of eval_4_isog computations
  for (i = 0; i < TESTS; i++) 
    eval_4_isog(pts[i], coeff);

  eval_4_isog(phiP, coeff);
  eval_4_isog(phiQ, coeff);
  eval_4_isog(phiR, coeff);

  t0 += cpucycles();


  // modular correction to reduce to range [0, p128-1]
  fpcorrection128(A24_0);
  fpcorrection128(A24_1);
  fpcorrection128(C24_0);
  fpcorrection128(C24_1);
  fpcorrection128(XPTS_0_0);
  fpcorrection128(XPTS_0_1);
  fpcorrection128(ZPTS_0_0);
  fpcorrection128(ZPTS_0_1); 
  fpcorrection128(XPTS_1_0);
  fpcorrection128(XPTS_1_1);
  fpcorrection128(ZPTS_1_0);
  fpcorrection128(ZPTS_1_1); 
  fpcorrection128(XPTS_2_0);
  fpcorrection128(XPTS_2_1);
  fpcorrection128(ZPTS_2_0);
  fpcorrection128(ZPTS_2_1); 
  fpcorrection128(XPTS_3_0);
  fpcorrection128(XPTS_3_1);
  fpcorrection128(ZPTS_3_0);
  fpcorrection128(ZPTS_3_1);
  fpcorrection128(XphiP_0);
  fpcorrection128(XphiP_1);
  fpcorrection128(ZphiP_0);
  fpcorrection128(ZphiP_1);
  fpcorrection128(XphiQ_0);
  fpcorrection128(XphiQ_1);
  fpcorrection128(ZphiQ_0);
  fpcorrection128(ZphiQ_1); 
  fpcorrection128(XphiR_0);
  fpcorrection128(XphiR_1);
  fpcorrection128(ZphiR_0);
  fpcorrection128(ZphiR_1); 
  
  // for get_4_isog
  // return A24, C24
  printf("\nresult A24_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", A24_0[i]); 
  }

  printf("\nresult A24_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", A24_1[i]); 
  }

  printf("\nresult C24_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", C24_0[i]); 
  }

  printf("\nresult C24_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", C24_1[i]); 
  }

  // for eval_4_isog
  // return pts[0], pts[1], pts[2], pts[3], phiP, phiQ, and phiR
  printf("\nresult XPTS_0_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_0_0[i]); 
  }

  printf("\nresult XPTS_0_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_0_1[i]); 
  }


  printf("\nresult ZPTS_0_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_0_0[i]); 
  }

  printf("\nresult ZPTS_0_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_0_1[i]); 
  }

  printf("\nresult XPTS_1_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_1_0[i]); 
  }

  printf("\nresult XPTS_1_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_1_1[i]); 
  }


  printf("\nresult ZPTS_1_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_1_0[i]); 
  }

  printf("\nresult ZPTS_1_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_1_1[i]); 
  }

  printf("\nresult XPTS_2_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_2_0[i]); 
  }

  printf("\nresult XPTS_2_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_2_1[i]); 
  }


  printf("\nresult ZPTS_2_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_2_0[i]); 
  }

  printf("\nresult ZPTS_2_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_2_1[i]); 
  }

  printf("\nresult XPTS_3_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_3_0[i]); 
  }

  printf("\nresult XPTS_3_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XPTS_3_1[i]); 
  }


  printf("\nresult ZPTS_3_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_3_0[i]); 
  }

  printf("\nresult ZPTS_3_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZPTS_3_1[i]); 
  }

  printf("\nresult XphiP_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiP_0[i]); 
  }

  printf("\nresult XphiP_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiP_1[i]); 
  }

  printf("\nresult ZphiP_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiP_0[i]); 
  }

  printf("\nresult ZphiP_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiP_1[i]); 
  }

  printf("\nresult XphiQ_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiQ_0[i]); 
  }

  printf("\nresult XphiQ_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiQ_1[i]); 
  }

  printf("\nresult ZphiQ_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiQ_0[i]); 
  }

  printf("\nresult ZphiQ_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiQ_1[i]); 
  }

  printf("\nresult XphiR_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiR_0[i]); 
  }

  printf("\nresult XphiR_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", XphiR_1[i]); 
  }

  printf("\nresult ZphiR_0:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiR_0[i]); 
  }

  printf("\nresult ZphiR_1:\n");

  for (int i=0; i<NWORDS_FIELD; i++) {
    printf("%d    ", i); 
    printf("%x\n", ZphiR_1[i]); 
  }  

  printf("\n------------PERFORMANCE------------\n\n");
  printf("cycles for get_4_isog_and_eval_4_isog in sw: %" PRIu64 "\n\n", t0); 

}