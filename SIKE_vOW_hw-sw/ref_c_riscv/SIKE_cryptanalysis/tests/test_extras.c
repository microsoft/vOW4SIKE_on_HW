/********************************************************************************************
* File from the SIDH library
*
* Abstract: utility functions for testing and benchmarking
*********************************************************************************************/

#include "test_extras.h"
#if (OS_TARGET == OS_WIN)
    #include <intrin.h>
    #include <windows.h>
#elif (OS_TARGET == OS_LINUX)
    #if (TARGET == TARGET_ARM64)
        #include <time.h>
    #endif
    #include <unistd.h>
#endif
#include <stdlib.h>     

#ifdef p_32_20           /* p128 = 2^32*3^20*23 - 1 */
    static uint64_t p128[2] = { 0xAC0E7A06FFFFFFFF, 0x0000000000000012 };
    #define NBITS_FIELD128     69
#elif defined p_36_22    /* p128 = 2^36*3^22*31 - 1 */
    static uint64_t p128[2] = { 0x02A0B06FFFFFFFFF, 0x0000000000000E28 };
    #define NBITS_FIELD128     76
#else
    static uint64_t p128[2] = { 0, 0 };
    #define NBITS_FIELD128    0
#endif
    
static uint64_t p377[6]  = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0x0B46D546BC2A5699, 0xA879CC6988CE7CF5, 0x015B702E0C542196 };
static uint64_t p434[7]  = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFDC1767AE2FFFFFF, 
                             0x7BC65C783158AEA3, 0x6CFC5FD681C52056, 0x0002341F27177344 };
static uint64_t p503[8]  = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xABFFFFFFFFFFFFFF, 
                             0x13085BDA2211E7A0, 0x1B9BF6C87B7E7DAF, 0x6045C6BDDA77A4D0, 0x004066F541811E1E };
static uint64_t p546[9]  = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xC1CCF59098E1FFFF, 
                             0x91CA3591A0810F4F, 0xC3A747738CBAAD7D, 0x3E568459654D5F6B, 0x000000030F5EBA42 };
static uint64_t p610[10] = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x6E01FFFFFFFFFFFF, 
                             0xB1784DE8AA5AB02E, 0x9AE7BF45048FF9AB, 0xB255B2FA10C4252A, 0x819010C251E7D88C, 0x000000027BF6A768 };
static uint64_t p697[11] = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x604054AFFFFFFFFF,
                             0xDF4970CF7313736F, 0x719AEC973BF54225, 0x40E474DA88B90FFE, 0x9A0E279D6CEB3C8E, 0x01B39F97671708CF };
static uint64_t p751[12] = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xEEAFFFFFFFFFFFFF,
                             0xE3EC968549F878A8, 0xDA959B1A13F7CC76, 0x084E9867D6EBE876, 0x8562B5045CB25748, 0x0E12909F97BADC66, 0x00006FE5D541F71C };

#define NBITS_FIELD377    377
#define NBITS_FIELD434    434
#define NBITS_FIELD503    503
#define NBITS_FIELD546    546
#define NBITS_FIELD610    610
#define NBITS_FIELD697    697
#define NBITS_FIELD751    751

#if defined(x86)
int64_t cpucycles(void)
{ // Access system counter for benchmarking
#if (OS_TARGET == OS_WIN) && (TARGET == TARGET_AMD64 || TARGET == TARGET_x86)
    return __rdtsc();
#elif (OS_TARGET == OS_LINUX) && (TARGET == TARGET_AMD64 || TARGET == TARGET_x86)
    unsigned int hi, lo;

    __asm volatile ("rdtsc\n\t" : "=a" (lo), "=d"(hi));
    return ((int64_t)lo) | (((int64_t)hi) << 32);
#elif (OS_TARGET == OS_LINUX) && (TARGET == TARGET_ARM64)
    struct timespec time;

    clock_gettime(CLOCK_REALTIME, &time);
    return (int64_t)(time.tv_sec*1e9 + time.tv_nsec);
#else
    return 0;            
#endif
}
#endif

int compare_words(digit_t* a, digit_t* b, unsigned int nwords)
{ // Comparing "nword" elements, a=b? : (1) a>b, (0) a=b, (-1) a<b
  // SECURITY NOTE: this function does not have constant-time execution. TO BE USED FOR TESTING ONLY.
    int i;

    for (i = nwords-1; i >= 0; i--)
    {
        if (a[i] > b[i]) return 1;
        else if (a[i] < b[i]) return -1;
    }

    return 0; 
}


static void sub_test(digit_t* a, digit_t* b, digit_t* c, unsigned int nwords)
{ // Subtraction without borrow, c = a-b where a>b
  // SECURITY NOTE: this function does not have constant-time execution. It is for TESTING ONLY.     
    unsigned int i;
    digit_t res, carry, borrow = 0;
  
    for (i = 0; i < nwords; i++)
    {
        res = a[i] - b[i];
        carry = (a[i] < b[i]);
        c[i] = res - borrow;
        borrow = carry || (res < borrow);
    } 
}


void fprandom128_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p128-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 128-NBITS_FIELD128, nwords = NBITS_TO_NWORDS(NBITS_FIELD128);                    
    unsigned char* string = NULL;

    for (i = 0; i < NBITS_TO_NWORDS(128); i++) a[i] = 0;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 128-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p128, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p128, a, nwords);
    }
}


void fprandom377_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p377-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 384-NBITS_FIELD377, nwords = NBITS_TO_NWORDS(NBITS_FIELD377);
    unsigned char* string = NULL;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 384-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p377, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p377, a, nwords);
    }
}


void fprandom434_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p434-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 448-NBITS_FIELD434, nwords = NBITS_TO_NWORDS(NBITS_FIELD434);
    unsigned char* string = NULL;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 448-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p434, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p434, a, nwords);
    }
}


void fprandom503_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p503-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 512-NBITS_FIELD503, nwords = NBITS_TO_NWORDS(NBITS_FIELD503);
    unsigned char* string = NULL;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 512-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p503, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p503, a, nwords);
    }
}


void fprandom546_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p546-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 576-NBITS_FIELD546, nwords = NBITS_TO_NWORDS(NBITS_FIELD546);
    unsigned char* string = NULL;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 576-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p546, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p546, a, nwords);
    }
}


void fprandom610_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p610-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 640-NBITS_FIELD610, nwords = NBITS_TO_NWORDS(NBITS_FIELD610);
    unsigned char* string = NULL;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 640-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p610, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p610, a, nwords);
    }
}


void fprandom697_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p697-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 704-NBITS_FIELD697, nwords = NBITS_TO_NWORDS(NBITS_FIELD697);
    unsigned char* string = NULL;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 640-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p697, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p697, a, nwords);
    }
}


void fprandom751_test(digit_t* a)
{ // Generating a pseudo-random field element in [0, p751-1] 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.
    unsigned int i, diff = 768-NBITS_FIELD751, nwords = NBITS_TO_NWORDS(NBITS_FIELD751);
    unsigned char* string = NULL;

    string = (unsigned char*)a;
    for (i = 0; i < sizeof(digit_t)*nwords; i++) {
        *(string + i) = (unsigned char)rand();              // Obtain 768-bit number
    }
    a[nwords-1] &= (((digit_t)(-1) << diff) >> diff);

    while (compare_words((digit_t*)p751, a, nwords) < 1) {  // Force it to [0, modulus-1]
        sub_test(a, (digit_t*)p751, a, nwords);
    }
}


void fp2random128_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p128^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom128_test(a);
    fprandom128_test(a+NBITS_TO_NWORDS(128));
}


void fp2random377_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p377^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom377_test(a);
    fprandom377_test(a+NBITS_TO_NWORDS(NBITS_FIELD377));
}


void fp2random434_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p434^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom434_test(a);
    fprandom434_test(a+NBITS_TO_NWORDS(NBITS_FIELD434));
}


void fp2random503_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p503^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom503_test(a);
    fprandom503_test(a+NBITS_TO_NWORDS(NBITS_FIELD503));
}


void fp2random546_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p546^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom546_test(a);
    fprandom546_test(a+NBITS_TO_NWORDS(NBITS_FIELD546));
}


void fp2random610_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p610^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom610_test(a);
    fprandom610_test(a+NBITS_TO_NWORDS(NBITS_FIELD610));
}


void fp2random697_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p697^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom697_test(a);
    fprandom697_test(a+NBITS_TO_NWORDS(NBITS_FIELD697));
}


void fp2random751_test(digit_t* a)
{ // Generating a pseudo-random element in GF(p751^2) 
  // SECURITY NOTE: distribution is not fully uniform. TO BE USED FOR TESTING ONLY.

    fprandom751_test(a);
    fprandom751_test(a+NBITS_TO_NWORDS(NBITS_FIELD751));
}


void sleep_ms(digit_t ms)
{
 #if (OS_TARGET == OS_WIN)
    Sleep((DWORD)ms);
#elif (OS_TARGET == OS_LINUX)
    usleep(ms*1000);
#endif
}