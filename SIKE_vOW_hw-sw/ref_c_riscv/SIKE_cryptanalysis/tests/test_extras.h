/********************************************************************************************
* File from the SIDH library
*
* Abstract: utility header file for tests
*********************************************************************************************/  

#ifndef __TEST_EXTRAS_H__
#define __TEST_EXTRAS_H__
    
#include "../../../ref_c/SIKE_vOW_software/src/config.h"

#define PASSED    0
#define FAILURE   1


#if (TARGET == TARGET_ARM64)
    #define print_unit printf("nsec");
#else
    #define print_unit printf("cycles");
#endif

    
// Access system counter for benchmarking
#if defined(x86)
int64_t cpucycles(void);
#endif

// Comparing "nword" elements, a=b? : (1) a!=b, (0) a=b
int compare_words(digit_t* a, digit_t* b, unsigned int nwords);

// Generating a pseudo-random field element in [0, p128-1] 
void fprandom128_test(digit_t* a);

// Generating a pseudo-random element in GF(p128^2)
void fp2random128_test(digit_t* a);

// Generating a pseudo-random field element in [0, p377-1] 
void fprandom377_test(digit_t* a);

// Generating a pseudo-random element in GF(p377^2)
void fp2random377_test(digit_t* a);

// Generating a pseudo-random field element in [0, p434-1] 
void fprandom434_test(digit_t* a);

// Generating a pseudo-random element in GF(p434^2)
void fp2random434_test(digit_t* a);

// Generating a pseudo-random field element in [0, p503-1] 
void fprandom503_test(digit_t* a);

// Generating a pseudo-random element in GF(p503^2)
void fp2random503_test(digit_t* a);

// Generating a pseudo-random field element in [0, p546-1] 
void fprandom546_test(digit_t* a);

// Generating a pseudo-random element in GF(p546^2)
void fp2random546_test(digit_t* a);

// Generating a pseudo-random field element in [0, p610-1] 
void fprandom610_test(digit_t* a);

// Generating a pseudo-random element in GF(p610^2)
void fp2random610_test(digit_t* a);

// Generating a pseudo-random field element in [0, p697-1] 
void fprandom697_test(digit_t* a);

// Generating a pseudo-random element in GF(p697^2)
void fp2random697_test(digit_t* a);

// Generating a pseudo-random field element in [0, p751-1] 
void fprandom751_test(digit_t* a);

// Generating a pseudo-random element in GF(p751^2)
void fp2random751_test(digit_t* a);

// Sleep a given number of milliseconds, platform independent
void sleep_ms(digit_t ms);
#endif