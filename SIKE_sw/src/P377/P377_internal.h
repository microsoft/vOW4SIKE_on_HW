/********************************************************************************************
* SIDH: an efficient supersingular isogeny cryptography library 
* Copyright (c) Microsoft Corporation
*
* Website: https://github.com/microsoft/PQCrypto-SIDH
* Released under MIT license
*
* Abstract: internal header file for P377
*********************************************************************************************/  

#ifndef P377_INTERNAL_H
#define P377_INTERNAL_H

#include "../config.h"
 

#if (TARGET == TARGET_AMD64) || (TARGET == TARGET_ARM64)
    #define NWORDS_FIELD    6               // Number of words of a 377-bit field element
    #define p377_ZERO_WORDS 2               // Number of "0" digits in the least significant part of p377 + 1     
#elif (TARGET == TARGET_x86)
    #define NWORDS_FIELD    12 
    #define p377_ZERO_WORDS 5
#endif
    

// Basic constants

#define NBITS_FIELD             377  
#define MAXBITS_FIELD           384                
#define MAXWORDS_FIELD          ((MAXBITS_FIELD+RADIX-1)/RADIX)     // Max. number of words to represent field elements
#define NWORDS64_FIELD          ((NBITS_FIELD+63)/64)               // Number of 64-bit words of a 377-bit field element 
#define NBITS_ORDER             192
#define NWORDS_ORDER            ((NBITS_ORDER+RADIX-1)/RADIX)       // Number of words of oA and oB, where oA and oB are the subgroup orders of Alice and Bob, resp.
#define NWORDS64_ORDER          ((NBITS_ORDER+63)/64)               // Number of 64-bit words of a 192-bit element 
#define MAXBITS_ORDER           NBITS_ORDER                         
#define ALICE                   0
#define BOB                     1 
#define OALICE_BITS             191  
#define OBOB_BITS               186     
#define OBOB_EXPON              117    
#define MASK_ALICE              0x7F
#define MASK_BOB                0x01 
#define PRIME                   p377 
#define PARAM_A                 6  
#define PARAM_C                 1
// Fixed parameters for isogeny tree computation
#define MAX_INT_POINTS_ALICE    7                 
#define MAX_INT_POINTS_BOB      8      
#define MAX_Alice               95
#define MAX_Bob                 117
#define MSG_BYTES               16
#define SECRETKEY_A_BYTES       ((OALICE_BITS + 7) / 8)
#define SECRETKEY_B_BYTES       ((OBOB_BITS - 1 + 7) / 8)
#define FP2_ENCODED_BYTES       2*((NBITS_FIELD + 7) / 8)


// SIDH's basic element definitions and point representations

typedef digit_t felm_t[NWORDS_FIELD];                                 // Datatype for representing 377-bit field elements (384-bit max.)
typedef digit_t dfelm_t[2*NWORDS_FIELD];                              // Datatype for representing double-precision 2x377-bit field elements (2x384-bit max.) 
typedef felm_t  f2elm_t[2];                                           // Datatype for representing quadratic extension field elements GF(p377^2)
        
typedef struct { f2elm_t X; f2elm_t Z; } point_proj;                  // Point representation in projective XZ Montgomery coordinates.
typedef point_proj point_proj_t[1];



/**************** Function prototypes ****************/
/************* Multiprecision functions **************/

// 377-bit multiprecision addition, c = a+b
void mp_add377(const digit_t* a, const digit_t* b, digit_t* c);
void mp_add377_asm(const digit_t* a, const digit_t* b, digit_t* c);

// 377-bit multiprecision subtraction, c = a-b+2p or c = a-b+4p
extern void mp_sub377_p2(const digit_t* a, const digit_t* b, digit_t* c);
extern void mp_sub377_p4(const digit_t* a, const digit_t* b, digit_t* c);
void mp_sub377_p2_asm(const digit_t* a, const digit_t* b, digit_t* c); 
void mp_sub377_p4_asm(const digit_t* a, const digit_t* b, digit_t* c); 

// 2x377-bit multiprecision subtraction followed by addition with p377*2^384, c = a-b+(p377*2^384) if a-b < 0, otherwise c=a-b 
void mp_subaddx2_asm(const digit_t* a, const digit_t* b, digit_t* c);
void mp_subadd377x2_asm(const digit_t* a, const digit_t* b, digit_t* c);

// Double 2x377-bit multiprecision subtraction, c = c-a-b, where c > a and c > b
void mp_dblsub377x2_asm(const digit_t* a, const digit_t* b, digit_t* c);

/************ Field arithmetic functions *************/

// Copy of a field element, c = a
void fpcopy377(const digit_t* a, digit_t* c);

// Zeroing a field element, a = 0
void fpzero377(digit_t* a);

// Non constant-time comparison of two field elements. If a = b return TRUE, otherwise, return FALSE
bool fpequal377_non_constant_time(const digit_t* a, const digit_t* b); 

// Modular addition, c = a+b mod p377
extern void fpadd377(const digit_t* a, const digit_t* b, digit_t* c);
extern void fpadd377_asm(const digit_t* a, const digit_t* b, digit_t* c);

// Modular subtraction, c = a-b mod p377
extern void fpsub377(const digit_t* a, const digit_t* b, digit_t* c);
extern void fpsub377_asm(const digit_t* a, const digit_t* b, digit_t* c);

// Modular negation, a = -a mod p377        
extern void fpneg377(digit_t* a);  

// Modular division by two, c = a/2 mod p377.
void fpdiv2_377(const digit_t* a, digit_t* c);

// Modular correction to reduce field element a in [0, 2*p377-1] to [0, p377-1].
void fpcorrection377(digit_t* a);

// 377-bit Montgomery reduction, c = a mod p
void rdc377_asm(digit_t* ma, digit_t* mc);
            
// Field multiplication using Montgomery arithmetic, c = a*b*R^-1 mod p377, where R=2^768
void fpmul377_mont(const digit_t* a, const digit_t* b, digit_t* c);
void mul377_asm(const digit_t* a, const digit_t* b, digit_t* c);
   
// Field squaring using Montgomery arithmetic, c = a*b*R^-1 mod p377, where R=2^768
void fpsqr377_mont(const digit_t* ma, digit_t* mc);

// Field inversion, a = a^-1 in GF(p377)
void fpinv377_mont(digit_t* a);

// Chain to compute (p377-3)/4 using Montgomery arithmetic
void fpinv377_chain_mont(digit_t* a);

/************ GF(p^2) arithmetic functions *************/
    
// Copy of a GF(p377^2) element, c = a
void fp2copy377(const f2elm_t a, f2elm_t c);

// Zeroing a GF(p377^2) element, a = 0
void fp2zero377(f2elm_t a);

// GF(p377^2) negation, a = -a in GF(p377^2)
void fp2neg377(f2elm_t a);

// GF(p377^2) addition, c = a+b in GF(p377^2)
extern void fp2add377(const f2elm_t a, const f2elm_t b, f2elm_t c);           

// GF(p377^2) subtraction, c = a-b in GF(p377^2)
extern void fp2sub377(const f2elm_t a, const f2elm_t b, f2elm_t c); 

// GF(p377^2) division by two, c = a/2  in GF(p377^2) 
void fp2div2_377(const f2elm_t a, f2elm_t c);

// Modular correction, a = a in GF(p377^2)
void fp2correction377(f2elm_t a);
            
// GF(p377^2) squaring using Montgomery arithmetic, c = a^2 in GF(p377^2)
void fp2sqr377_mont(const f2elm_t a, f2elm_t c);
 
// GF(p377^2) multiplication using Montgomery arithmetic, c = a*b in GF(p377^2)
void fp2mul377_mont(const f2elm_t a, const f2elm_t b, f2elm_t c);

// GF(p377^2) inversion using Montgomery arithmetic, a = (a0-i*a1)/(a0^2+a1^2)
void fp2inv377_mont(f2elm_t a);


#endif
