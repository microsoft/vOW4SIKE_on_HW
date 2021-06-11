/********************************************************************************************
* vOW4SIKE on HW: a HW/SW co-design implementation of the vOW algorithm on SIKE
* Copyright (c) Microsoft Corporation
*
* Website: https://github.com/microsoft/vOW4SIKE_on_HW
* Released under MIT license
*
* Based on the SIDH library (https://github.com/microsoft/PQCrypto-SIDH) and the vOW4SIKE
* library (https://github.com/microsoft/vOW4SIKE)
*
* Abstract: internal header file for P546
*********************************************************************************************/  

#ifndef P546_INTERNAL_H
#define P546_INTERNAL_H

#include "../config.h"
 

#if (TARGET == TARGET_AMD64) || (TARGET == TARGET_ARM64)
    #define NWORDS_FIELD    9               // Number of words of a 546-bit field element
    #define p546_ZERO_WORDS 4               // Number of "0" digits in the least significant part of p546 + 1    
#elif (TARGET == TARGET_x86)
    #define NWORDS_FIELD    18
    #define p546_ZERO_WORDS 8
#endif
    

// Basic constants

#define NBITS_FIELD             546  
#define MAXBITS_FIELD           576                
#define MAXWORDS_FIELD          ((MAXBITS_FIELD+RADIX-1)/RADIX)     // Max. number of words to represent field elements
#define NWORDS64_FIELD          ((NBITS_FIELD+63)/64)               // Number of 64-bit words of a 546-bit field element 
#define NBITS_ORDER             320
#define NWORDS_ORDER            ((NBITS_ORDER+RADIX-1)/RADIX)       // Number of words of oA and oB, where oA and oB are the subgroup orders of Alice and Bob, resp.
#define NWORDS64_ORDER          ((NBITS_ORDER+63)/64)               // Number of 64-bit words of a 256-bit element 
#define MAXBITS_ORDER           NBITS_ORDER
#define ALICE                   0
#define BOB                     1 
#define OALICE_BITS             273  
#define OBOB_BITS               273     
#define OBOB_EXPON              172    
#define MASK_ALICE              0x01 
#define MASK_BOB                0xFF 
#define PRIME                   p546 
#define PARAM_A                 6  
#define PARAM_C                 1
// Fixed parameters for isogeny tree computation
#define MAX_INT_POINTS_ALICE    8
#define MAX_INT_POINTS_BOB      8    
#define MAX_Alice               136
#define MAX_Bob                 172
#define MSG_BYTES               24
#define SECRETKEY_A_BYTES       ((OALICE_BITS + 7) / 8)
#define SECRETKEY_B_BYTES       ((OBOB_BITS - 1 + 7) / 8)
#define FP2_ENCODED_BYTES       2*((NBITS_FIELD + 7) / 8)


// SIDH's basic element definitions and point representations

typedef digit_t felm_t[NWORDS_FIELD];                                 // Datatype for representing 546-bit field elements (576-bit max.)
typedef digit_t dfelm_t[2*NWORDS_FIELD];                              // Datatype for representing double-precision 2x546-bit field elements (2x576-bit max.) 
typedef felm_t  f2elm_t[2];                                           // Datatype for representing quadratic extension field elements GF(p546^2)
        
typedef struct { f2elm_t X; f2elm_t Z; } point_proj;                  // Point representation in projective XZ Montgomery coordinates.
typedef point_proj point_proj_t[1]; 

#ifdef COMPRESS
    typedef struct { f2elm_t X; f2elm_t Y; f2elm_t Z; } point_full_proj;  // Point representation in full projective XYZ Montgomery coordinates 
    typedef point_full_proj point_full_proj_t[1]; 

    typedef struct { f2elm_t x; f2elm_t y; } point_affine;                // Point representation in affine coordinates.
    typedef point_affine point_t[1]; 

    typedef f2elm_t publickey_t[3];      
#endif



/**************** Function prototypes ****************/
/************* Multiprecision functions **************/

// 546-bit multiprecision addition, c = a+b
void mp_add546(const digit_t* a, const digit_t* b, digit_t* c);
void mp_add546_asm(const digit_t* a, const digit_t* b, digit_t* c);

// 546-bit multiprecision subtraction, c = a-b+2p or c = a-b+4p
extern void mp_sub546_p2(const digit_t* a, const digit_t* b, digit_t* c);
extern void mp_sub546_p4(const digit_t* a, const digit_t* b, digit_t* c);
void mp_sub546_p2_asm(const digit_t* a, const digit_t* b, digit_t* c); 
void mp_sub546_p4_asm(const digit_t* a, const digit_t* b, digit_t* c); 

// 2x546-bit multiprecision subtraction followed by addition with p546*2^576, c = a-b+(p546*2^576) if a-b < 0, otherwise c=a-b 
void mp_subaddx2_asm(const digit_t* a, const digit_t* b, digit_t* c);
void mp_subadd546x2_asm(const digit_t* a, const digit_t* b, digit_t* c);

// Double 2x546-bit multiprecision subtraction, c = c-a-b, where c > a and c > b
void mp_dblsub546x2_asm(const digit_t* a, const digit_t* b, digit_t* c);

/************ Field arithmetic functions *************/

// Copy of a field element, c = a
void fpcopy546(const digit_t* a, digit_t* c);

// Zeroing a field element, a = 0
void fpzero546(digit_t* a);

// Non constant-time comparison of two field elements. If a = b return TRUE, otherwise, return FALSE
bool fpequal546_non_constant_time(const digit_t* a, const digit_t* b); 

// Modular addition, c = a+b mod p546
extern void fpadd546(const digit_t* a, const digit_t* b, digit_t* c);
extern void fpadd546_asm(const digit_t* a, const digit_t* b, digit_t* c);

// Modular subtraction, c = a-b mod p546
extern void fpsub546(const digit_t* a, const digit_t* b, digit_t* c);
extern void fpsub546_asm(const digit_t* a, const digit_t* b, digit_t* c);

// Modular negation, a = -a mod p546        
extern void fpneg546(digit_t* a);  

// Modular division by two, c = a/2 mod p546.
void fpdiv2_546(const digit_t* a, digit_t* c);

// Modular correction to reduce field element a in [0, 2*p546-1] to [0, p546-1].
void fpcorrection546(digit_t* a);

// 546-bit Montgomery reduction, c = a mod p
void rdc546_asm(digit_t* ma, digit_t* mc);
            
// Field multiplication using Montgomery arithmetic, c = a*b*R^-1 mod p546, where R=2^768
void fpmul546_mont(const digit_t* a, const digit_t* b, digit_t* c);
void mul546_asm(const digit_t* a, const digit_t* b, digit_t* c);
   
// Field squaring using Montgomery arithmetic, c = a*b*R^-1 mod p546, where R=2^768
void fpsqr546_mont(const digit_t* ma, digit_t* mc);

// Field inversion, a = a^-1 in GF(p546)
void fpinv546_mont(digit_t* a);

// Chain to compute (p546-3)/4 using Montgomery arithmetic
void fpinv546_chain_mont(digit_t* a);

/************ GF(p^2) arithmetic functions *************/
    
// Copy of a GF(p546^2) element, c = a
void fp2copy546(const f2elm_t a, f2elm_t c);

// Zeroing a GF(p546^2) element, a = 0
void fp2zero546(f2elm_t a);

// GF(p546^2) negation, a = -a in GF(p546^2)
void fp2neg546(f2elm_t a);

// GF(p546^2) addition, c = a+b in GF(p546^2)
extern void fp2add546(const f2elm_t a, const f2elm_t b, f2elm_t c);           

// GF(p546^2) subtraction, c = a-b in GF(p546^2)
extern void fp2sub546(const f2elm_t a, const f2elm_t b, f2elm_t c); 

// GF(p546^2) division by two, c = a/2  in GF(p546^2) 
void fp2div2_546(const f2elm_t a, f2elm_t c);

// Modular correction, a = a in GF(p546^2)
void fp2correction546(f2elm_t a);
            
// GF(p546^2) squaring using Montgomery arithmetic, c = a^2 in GF(p546^2)
void fp2sqr546_mont(const f2elm_t a, f2elm_t c);
 
// GF(p546^2) multiplication using Montgomery arithmetic, c = a*b in GF(p546^2)
void fp2mul546_mont(const f2elm_t a, const f2elm_t b, f2elm_t c);

// GF(p546^2) inversion using Montgomery arithmetic, a = (a0-i*a1)/(a0^2+a1^2)
void fp2inv546_mont(f2elm_t a);


#endif
