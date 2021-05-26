/********************************************************************************************
* SIDH: an efficient supersingular isogeny cryptography library 
* Copyright (c) Microsoft Corporation
*
* Website: https://github.com/microsoft/PQCrypto-SIDH
* Released under MIT license
*
* Abstract: supersingular isogeny parameters and generation of functions for P546
*********************************************************************************************/  

#include "P546_api.h" 
#include "P546_internal.h"
#include "../internal.h"


// Encoding of field elements, elements over Z_order, elements over GF(p^2) and elliptic curve points:
// --------------------------------------------------------------------------------------------------
// Elements over GF(p) and Z_order are encoded with the least significant octet (and digit) located at the leftmost position (i.e., little endian format). 
// Elements (a+b*i) over GF(p^2), where a and b are defined over GF(p), are encoded as {a, b}, with a in the least significant position.
// Elliptic curve points P = (x,y) are encoded as {x, y}, with x in the least significant position. 
// Internally, the number of digits used to represent all these elements is obtained by approximating the number of bits to the immediately greater multiple of 32.
// For example, a 546-bit field element is represented with Ceil(546 / 64) = 9 64-bit digits or Ceil(546 / 32) = 18 32-bit digits.

//
// Curve isogeny system "SIDHp546". Base curve: Montgomery curve By^2 = Cx^3 + Ax^2 + Cx defined over GF(p546^2), where A=6, B=1, C=1 and p546 = 2^273*3^172-1
//
         
const uint64_t p546[NWORDS64_FIELD]              = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xC1CCF59098E1FFFF, 
                                                     0x91CA3591A0810F4F, 0xC3A747738CBAAD7D, 0x3E568459654D5F6B, 0x000000030F5EBA42 };
const uint64_t p546p1[NWORDS64_FIELD]            = { 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0xC1CCF59098E20000,
                                                     0x91CA3591A0810F4F, 0xC3A747738CBAAD7D, 0x3E568459654D5F6B, 0x000000030F5EBA42 };
const uint64_t p546x2[NWORDS64_FIELD]            = { 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x8399EB2131C3FFFF,
                                                     0x23946B2341021E9F, 0x874E8EE719755AFB, 0x7CAD08B2CA9ABED7, 0x000000061EBD7484 }; 
const uint64_t p546x4[NWORDS64_FIELD]            = { 0xFFFFFFFFFFFFFFFC, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x0733D6426387FFFF,
                                                     0x4728D64682043D3F, 0x0E9D1DCE32EAB5F6, 0xF95A116595357DAF, 0x0000000C3D7AE908 };
// Order of Alice's subgroup
const uint64_t Alice_order[NWORDS64_ORDER]       = { 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000020000 }; 
// Order of Bob's subgroup
const uint64_t Bob_order[NWORDS64_ORDER]         = { 0x87A7E0E67AC84C71, 0x56BEC8E51AC8D040, 0xAFB5E1D3A3B9C65D, 0x5D211F2B422CB2A6, 0x00000000000187AF };
// Alice's generator values {XPA0 + XPA1*i, XQA0 + XQA1*i, XRA0 + XRA1*i} in GF(p546^2), expressed in Montgomery representation
const uint64_t A_gen[6*NWORDS64_FIELD]           = { 0x8BF8B5CDA3529A11, 0x920F7AF8D8EDA1CE, 0x6A4FD6F4E65D2601, 0xAA5FDD88E6C8C053, 0x2DDFECC4564DD092,
                                                     0xB5AE8E8B63CDD2EB, 0xF5530B1581D37EFC, 0xBB69799BE0974397, 0x000000029E924174,   // XPA0
                                                     0x02BAA3F5AA08FBA0, 0xDF5E66F9718B1DB3, 0x7AAD305C4C16B9B5, 0xEFC538F7C899EC44, 0xB2B7A11B88589305,
                                                     0xF4C2FE11D652F55A, 0x45F5A4010B37F36F, 0x68C0BE35B4414691, 0x00000002974A76B9,   // XPA1
                                                     0x6655849EE4AD62B0, 0xA7B09BDA24F18E3D, 0xD9DC9DF1EFE6D4E3, 0x5618AE214D22122F, 0x35CE7CD8878AB07,
                                                     0xDFBE3687D874F305, 0x0FFAC636361A0289, 0x732304C3E314E9F3, 0x00000002D4829F4D,   // XQA0
                                                     0xD433C9386F41F07B, 0x591D74E6B6E16886, 0x1E91924E4D82BEA1, 0xE9ED0654FE5D746F, 0x95029EF76C0961D9,
                                                     0x9C5798078846CCA8, 0xB8AD7EC5421DCE49, 0xEBEF3DD3098146F8, 0x000000010E9A2BCA,   // XQA1
                                                     0xC218DF11E1FCA67A, 0x8C622C3530976AAF, 0xC5A558DA88A028C1, 0x5B0E218835EB3EEA, 0x63B412D6B77F6E5F,
                                                     0x44265EEA17A1F58C, 0xD7A6BD5FE291AA13, 0xC0918F65ED8D3D23, 0x000000005562DBCD,   // XRA0
                                                     0x071F4177BDD2E021, 0xDC8F3873504C93E7, 0x77038B491A006DB7, 0x9E205A8C15B8F717, 0x701734570E79CC07,
                                                     0x0790455A85462B3D, 0x19AC9F7FC32A9F20, 0x04B599768492F2D5, 0x0000000248379BC7 }; // XRA1
// Bob's generator values {XPB0, XQB0, XRB0 + XRB1*i} in GF(p546^2), expressed in Montgomery representation
const uint64_t B_gen[6*NWORDS64_FIELD]           = { 0xC60DC8B9DD8A126C, 0x2841B16BD9C550AB, 0x33EB13E27326D027, 0xB4E345D7318893D7, 0x4F7BD19633EAA269,
                                                     0xA93049DB038741F4, 0x93222D9F331C2848, 0x15FFBA19339361F0, 0x0000000089E90060,   // XPB0
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,   // XPB1
                                                     0xA07EEF3334ACF340, 0x417F1E66A839DFCB, 0x45C32C88DAA25A10, 0x563B27FA6991C6BF, 0x4BE0CC5C10D513A9,
                                                     0xE4E1756C009BD03E, 0xAFDFBF640F2717AC, 0xDC5EE9B702D8E56C, 0x0000000182A09EB0,   // XQB0
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,   // XQB1
                                                     0x74937ACDD796D6EE, 0x7C5E906509CE108B, 0xDA57EBEF8BA73940, 0x1E5CB85A8E1C9A4C, 0xD4EBE9C3A955BB62,
                                                     0xBA4C02A05B39742F, 0x21A4B5BCACC33156, 0xE96E8BD54B98A20C, 0x0000000104B99E73,   // XRB0
                                                     0xEEFADB5C4965D7A8, 0xE653CE9D2DB5CD75, 0xB511FF5416DEAB7C, 0xA5D5B131D1112DEF, 0x72D33ED20BB3EB46,
                                                     0x96809017849D85DF, 0x00BA691C5F526CFF, 0x9B384D1CF1873823, 0x0000000152691238 }; // XRB1                                                     
// Montgomery constant Montgomery_R2 = (2^576)^2 mod p546
const uint64_t Montgomery_R2[NWORDS64_FIELD]     = { 0x52EB0249395B3348, 0x984F8851AEFDB3F3, 0x913744158E52803C, 0x1EC818C9E0CA0DA3, 0x4C2396C7E7350E87,
                                                     0x75D4E9F73AC13B39, 0x1640A26835D93C44, 0x5D441830B61AD042, 0x00000001357E298F };                                                    
// Value one in Montgomery representation 
const uint64_t Montgomery_one[NWORDS64_FIELD]    = { 0x0000000053A8B821, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0xAB9ED029DADE0000,
                                                     0x7FD34034A42F114D, 0x319FDC331E9125F5, 0xF1361EF3C5499C8A, 0x00000001393B6AF7 };


// Fixed parameters for isogeny tree computation
const unsigned int strat_Alice[MAX_Alice-1] = { 
65, 33, 17, 9, 5, 3, 2, 1, 1, 1, 1, 2, 1, 1, 1, 4, 2, 1, 1, 1, 2, 1, 1, 8, 4,
2, 1, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 16, 8, 4, 2, 1, 1, 1, 2, 1, 1, 4, 2,
1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 32, 16, 8, 4, 2, 1,
1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1,
16, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1,
1, 2, 1, 1 };

const unsigned int strat_Bob[MAX_Bob-1] = { 
71, 43, 27, 15, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 7, 4, 2, 1, 1, 2, 1,
1, 3, 2, 1, 1, 1, 1, 12, 7, 4, 2, 1, 1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 5, 3, 2, 1, 1,
1, 1, 2, 1, 1, 1, 17, 11, 7, 4, 2, 1, 1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 4, 3, 2, 1, 1,
1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 33, 17, 9, 5, 3, 2,
1, 1, 1, 1, 2, 1, 1, 1, 4, 2, 1, 1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 1, 2, 1, 1, 4, 2, 1,
1, 2, 1, 1, 16, 8, 4, 2, 1, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 2, 1,
1, 4, 2, 1, 1, 2, 1, 1 };
           
// Setting up macro defines and including GF(p), GF(p^2), curve, isogeny and kex functions
#define fpcopy                        fpcopy546
#define fpzero                        fpzero546
#define fpadd                         fpadd546
#define fpsub                         fpsub546
#define fpneg                         fpneg546
#define fpdiv2                        fpdiv2_546
#define fpcorrection                  fpcorrection546
#define fpmul_mont                    fpmul546_mont
#define fpsqr_mont                    fpsqr546_mont
#define fpinv_mont                    fpinv546_mont
#define fpinv_chain_mont              fpinv546_chain_mont
#define fp2copy                       fp2copy546
#define fp2zero                       fp2zero546
#define fp2add                        fp2add546
#define fp2sub                        fp2sub546
#define mp_sub_p2                     mp_sub546_p2
#define mp_sub_p4                     mp_sub546_p4
#define sub_p4                        mp_sub_p4
#define fp2neg                        fp2neg546
#define fp2div2                       fp2div2_546
#define fp2correction                 fp2correction546
#define fp2mul_mont                   fp2mul546_mont
#define fp2sqr_mont                   fp2sqr546_mont
#define fp2inv_mont                   fp2inv546_mont
#define fp2inv_mont_ct                fp2inv546_mont_ct
#define fp2inv_mont_bingcd            fp2inv546_mont_bingcd
#define mp_add_asm                    mp_add546_asm
#define mp_subaddx2_asm               mp_subadd546x2_asm
#define mp_dblsubx2_asm               mp_dblsub546x2_asm
#define crypto_kem_keypair            crypto_kem_keypair_SIKEp546
#define crypto_kem_enc                crypto_kem_enc_SIKEp546
#define crypto_kem_dec                crypto_kem_dec_SIKEp546
#define random_mod_order_A            random_mod_order_A_SIDHp546
#define random_mod_order_B            random_mod_order_B_SIDHp546
#define EphemeralKeyGeneration_A      EphemeralKeyGeneration_A_SIDHp546
#define EphemeralKeyGeneration_B      EphemeralKeyGeneration_B_SIDHp546
#define EphemeralSecretAgreement_A    EphemeralSecretAgreement_A_SIDHp546
#define EphemeralSecretAgreement_B    EphemeralSecretAgreement_B_SIDHp546

#include "../fpx.c"
#include "../ec_isogeny.c"
#include "../sidh.c"    
#include "../sike.c"