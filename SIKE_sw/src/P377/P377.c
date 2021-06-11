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
* Abstract: supersingular isogeny parameters and generation of functions for P377
*********************************************************************************************/ 

#include "P377_api.h" 
#include "P377_internal.h"
#include "../internal.h"


// Encoding of field elements, elements over Z_order, elements over GF(p^2) and elliptic curve points:
// --------------------------------------------------------------------------------------------------
// Elements over GF(p) and Z_order are encoded with the least significant octet (and digit) located at the leftmost position (i.e., little endian format). 
// Elements (a+b*i) over GF(p^2), where a and b are defined over GF(p), are encoded as {a, b}, with a in the least significant position.
// Elliptic curve points P = (x,y) are encoded as {x, y}, with x in the least significant position. 
// Internally, the number of digits used to represent all these elements is obtained by approximating the number of bits to the immediately greater multiple of 32.
// For example, a 377-bit field element is represented with Ceil(377 / 64) = 6 64-bit digits or Ceil(377 / 32) = 12 32-bit digits.

//
// Curve isogeny system "SIDHp377". Base curve: Montgomery curve By^2 = Cx^3 + Ax^2 + Cx defined over GF(p377^2), where A=6, B=1, C=1 and p377 = 2^191*3^117-1
//
         
const uint64_t p377[NWORDS64_FIELD]              = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0x0B46D546BC2A5699, 0xA879CC6988CE7CF5, 0x015B702E0C542196 };
const uint64_t p377x2[NWORDS64_FIELD]            = { 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x168DAA8D7854AD32, 0x50F398D3119CF9EA, 0x02B6E05C18A8432D }; 
const uint64_t p377x4[NWORDS64_FIELD]            = { 0xFFFFFFFFFFFFFFFC, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x2D1B551AF0A95A65, 0xA1E731A62339F3D4, 0x056DC0B83150865A };  
const uint64_t p377p1[NWORDS64_FIELD]            = { 0x0000000000000000, 0x0000000000000000, 0x8000000000000000, 0x0B46D546BC2A5699, 0xA879CC6988CE7CF5, 0x015B702E0C542196 };
const uint64_t p377p1x2[NWORDS64_FIELD/2]        = { 0x168DAA8D7854AD33, 0x50F398D3119CF9EA, 0x02B6E05C18A8432D };
const uint64_t p377x16p[2*NWORDS64_FIELD]        = { 0x0000000000000010, 0x0000000000000000, 0x0000000000000000, 0x972557287AB52CD0, 0xF0C672CEE630615E, 0xD491FA3E757BCD2A, 
                                                     0x2830123FBA97E0A3, 0x44E67AC0C81C9117, 0x942C5A8EFDDE690C, 0x63BDE5C206F0021D, 0xAA49E8B73CCD899E, 0x001D7894DFDBF251 }; 
// Order of Alice's subgroup
const uint64_t Alice_order[NWORDS64_ORDER]       = { 0x0000000000000000, 0x0000000000000000, 0x8000000000000000 };
// Order of Bob's subgroup
const uint64_t Bob_order[NWORDS64_ORDER]         = { 0x168DAA8D7854AD33, 0x50F398D3119CF9EA, 0x02B6E05C18A8432D };
// Alice's generator values {XPA0 + XPA1*i, XQA0 + xQA1*i, XRA0 + XRA1*i} in GF(p377^2), expressed in Montgomery representation
const uint64_t A_gen[6*NWORDS64_FIELD]           = { 0x8AE392AA8312F880, 0xDB7F6BA38CC56011, 0x896F67240AD52C67, 0x21B9C0BD6C0584FF, 0xF064B97DDD0B2BD4, 0x0102EA98B786D4CC,   // XPA0
                                                     0x583DE90ED3D09845, 0x131B1BDFBBE25620, 0x054B16A62F3D59F1, 0x1C3A458EEFFD4A0B, 0x1FBC000608BE1F7A, 0x00225F4BEEF34209,   // XPA1
                                                     0x8AA130E98FE00DE5, 0x6B54CC5A0A538778, 0x46D96D4F04F6605D, 0x069A3CAB971973AE, 0x8923D0F2112DA219, 0x0085C1C47AD21A2A,   // XQA0
                                                     0x50981EA202812D84, 0x61883F048CF1682A, 0x2DBC9EC88567E391, 0xD5E238E99DD189E7, 0x1BFE095BC910EA7D, 0x00203E87957453EB,   // XQA1
                                                     0x296CA63890082DB3, 0x02E16D4D70C2C55A, 0xD4B8FE9CB9481E99, 0xF95F9798C3BECDFB, 0x71B3A2D8A38CB84B, 0x0118DD7682525B04,   // XRA0
                                                     0xF64DD26CEC6E9DF5, 0xBC02B5979FF4F94C, 0x5D8B16849129DE49, 0xE44435C64BEFB9E9, 0x1077D183B5A4727B, 0x0019A2DF755CF268 }; // XRA1
// Bob's generator values {XPB0, XQB0, XRB0 + XRB1*i} in GF(p377^2), expressed in Montgomery representation
const uint64_t B_gen[6*NWORDS64_FIELD]           = { 0x436424EE3C9446F8, 0xB013A914D96E976D, 0x30C376697D926658, 0xE99792AFAA115E68, 0x935421EF522A946B, 0x0032474AECB8799E,   // XPB0 
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,   // XPB1
                                                     0x5EDE445E538850BC, 0x5BA7DAD976595394, 0xF01F46B8519CD118, 0x9DFA5CB5B40775A1, 0xC7E535F99811B56B, 0x0025BF8D8B00A170,   // XQB0
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,   // XQB1
                                                     0xA35AA9C8EA887C42, 0xE5A1BF165361C81A, 0x719BB1C6D6C727C7, 0x348590861EB46882, 0xB57273062A50C238, 0x002C53E0163A1C34,   // XRB0
                                                     0xF12E87A9F00803D8, 0x49C966997253584C, 0x58BBD82219B363ED, 0x6232DFE1A85929F5, 0xC85434A71BF3CC30, 0x005DE7FAB257510D }; // XRB1
// Montgomery constant Montgomery_R2 = (2^384)^2 mod p377
const uint64_t Montgomery_R2[NWORDS64_FIELD]     = { 0x826E131D3839C923, 0x54892C7B7D73E7F7, 0x3F8957D221B867A3, 0xD1217CD71D03BB94, 0xDCCBFB71E3AE5457, 0x00FCC56B6CD4B219 };                                                   
// Value one in Montgomery representation 
const uint64_t Montgomery_one[NWORDS64_FIELD]    = { 0x00000000000000BC, 0x0000000000000000, 0x0000000000000000, 0xB7FB600DD0E86746, 0x468DE27F885C3C0B, 0x00D99E2EF237555C };


// Fixed parameters for isogeny tree computation
const unsigned int strat_Alice[MAX_Alice-1] = { 
38, 26, 15, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 7, 4, 2, 1, 1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 11, 7, 4, 2, 1, 1, 2,
1, 1, 3, 2, 1, 1, 1, 1, 4, 3, 2, 1, 1, 1, 1, 2, 1, 1, 17, 9, 5, 3, 2, 1, 1, 1, 1, 2, 1, 1, 1, 4, 2, 1, 1, 1, 2, 1, 1, 8, 
4, 2, 1, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1 };

const unsigned int strat_Bob[MAX_Bob-1] = { 
54, 31, 16, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 15, 8, 4, 2, 1, 1,
2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 7, 4, 2, 1, 1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 23, 15, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 
1, 7, 4, 2, 1, 1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 9, 6, 4, 2, 1, 1, 2, 1, 1, 2, 2, 1, 1, 1, 4, 2, 1, 1, 1, 2, 1, 1 };
           
// Setting up macro defines and including GF(p), GF(p^2), curve, isogeny and kex functions
#define fpcopy                        fpcopy377
#define fpzero                        fpzero377
#define fpadd                         fpadd377
#define fpsub                         fpsub377
#define fpneg                         fpneg377
#define fpdiv2                        fpdiv2_377
#define fpcorrection                  fpcorrection377
#define fpmul_mont                    fpmul377_mont
#define fpsqr_mont                    fpsqr377_mont
#define fpinv_mont                    fpinv377_mont
#define fpinv_chain_mont              fpinv377_chain_mont
#define fp2copy                       fp2copy377
#define fp2zero                       fp2zero377
#define fp2add                        fp2add377
#define fp2sub                        fp2sub377
#define mp_sub_p2                     mp_sub377_p2
#define mp_sub_p4                     mp_sub377_p4
#define sub_p4                        mp_sub_p4
#define fp2neg                        fp2neg377
#define fp2div2                       fp2div2_377
#define fp2correction                 fp2correction377
#define fp2mul_mont                   fp2mul377_mont
#define fp2sqr_mont                   fp2sqr377_mont
#define fp2inv_mont                   fp2inv377_mont
#define fp2inv_mont_ct                fp2inv377_mont_ct
#define fp2inv_mont_bingcd            fp2inv377_mont_bingcd
#define fpequal_non_constant_time     fpequal377_non_constant_time
#define mp_add_asm                    mp_add377_asm
#define mp_subaddx2_asm               mp_subadd377x2_asm
#define mp_dblsubx2_asm               mp_dblsub377x2_asm
#define crypto_kem_keypair            crypto_kem_keypair_SIKEp377
#define crypto_kem_enc                crypto_kem_enc_SIKEp377
#define crypto_kem_dec                crypto_kem_dec_SIKEp377
#define random_mod_order_A            random_mod_order_A_SIDHp377
#define random_mod_order_B            random_mod_order_B_SIDHp377
#define EphemeralKeyGeneration_A      EphemeralKeyGeneration_A_SIDHp377
#define EphemeralKeyGeneration_B      EphemeralKeyGeneration_B_SIDHp377
#define EphemeralSecretAgreement_A    EphemeralSecretAgreement_A_SIDHp377
#define EphemeralSecretAgreement_B    EphemeralSecretAgreement_B_SIDHp377

#include "../fpx.c"
#include "../ec_isogeny.c"
#include "../sidh.c"    
#include "../sike.c"