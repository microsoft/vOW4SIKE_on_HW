/********************************************************************************************
* SIDH: an efficient supersingular isogeny cryptography library 
* Copyright (c) Microsoft Corporation
*
* Website: https://github.com/microsoft/PQCrypto-SIDH
* Released under MIT license
*
* Abstract: supersingular isogeny parameters and generation of functions for P697
*********************************************************************************************/  

#include "P697_api.h" 
#include "P697_internal.h"
#include "../internal.h"


// Encoding of field elements, elements over Z_order, elements over GF(p^2) and elliptic curve points:
// --------------------------------------------------------------------------------------------------
// Elements over GF(p) and Z_order are encoded with the least significant octet (and digit) located at the leftmost position (i.e., little endian format). 
// Elements (a+b*i) over GF(p^2), where a and b are defined over GF(p), are encoded as {a, b}, with a in the least significant position.
// Elliptic curve points P = (x,y) are encoded as {x, y}, with x in the least significant position. 
// Internally, the number of digits used to represent all these elements is obtained by approximating the number of bits to the immediately greater multiple of 32.
// For example, a 697-bit field element is represented with Ceil(697 / 64) = 11 64-bit digits or Ceil(697 / 32) = 22 32-bit digits.

//
// Curve isogeny system "SIDHp697". Base curve: Montgomery curve By^2 = Cx^3 + Ax^2 + Cx defined over GF(p697^2), where A=6, B=1, C=1 and p697 = 2^356*3^215-1
//
         
const uint64_t p697[NWORDS64_FIELD]              = { 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x604054AFFFFFFFFF,
                                                     0xDF4970CF7313736F, 0x719AEC973BF54225, 0x40E474DA88B90FFE, 0x9A0E279D6CEB3C8E, 0x01B39F97671708CF };
const uint64_t p697p1[NWORDS64_FIELD]            = { 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x604054B000000000,
                                                     0xDF4970CF7313736F, 0x719AEC973BF54225, 0x40E474DA88B90FFE, 0x9A0E279D6CEB3C8E, 0x01B39F97671708CF };
const uint64_t p697x2[NWORDS64_FIELD]            = { 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xC080A95FFFFFFFFF,
                                                     0xBE92E19EE626E6DE, 0xE335D92E77EA844B, 0x81C8E9B511721FFC, 0x341C4F3AD9D6791C, 0x03673F2ECE2E119F }; 
const uint64_t p697x4[NWORDS64_FIELD]            = { 0xFFFFFFFFFFFFFFFC, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x810152BFFFFFFFFF,
                                                     0x7D25C33DCC4DCDBD, 0xC66BB25CEFD50897, 0x0391D36A22E43FF9, 0x68389E75B3ACF239, 0x06CE7E5D9C5C233E };
// Order of Alice's subgroup
const uint64_t Alice_order[NWORDS64_ORDER]       = { 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000001000000000 }; 
// Order of Bob's subgroup
const uint64_t Bob_order[NWORDS64_ORDER]         = { 0xF7313736F604054B, 0x73BF54225DF4970C, 0xA88B90FFE719AEC9, 0xD6CEB3C8E40E474D, 0x7671708CF9A0E279, 0x00000000001B39F9 };
// Alice's generator values {XPA0 + XPA1*i, XQA0 + XQA1*i, XRA0 + XRA1*i} in GF(p697^2), expressed in Montgomery representation
const uint64_t A_gen[6*NWORDS64_FIELD]           = { 0xAED913E7D94626F9, 0x6F163E13CE243B16, 0x63211BC832B204DD, 0x35C03D027DA18195, 0x4AC8AE5E92D9A2E0, 0x7901C981FA69E5F6,
                                                     0xDC074593C4951783, 0xE039A85DA8C4CCCB, 0x238709FB5A391A27, 0x81C303327E8FDA3A, 0x000F36173BC9782E,   // XPA0
                                                     0x266F82DA9F627219, 0xC25C277AD1F10869, 0x947D3148A5C130AB, 0xFC5142FE8F622A88, 0xB5F69FFF2BA5CDB9, 0xA5B6DC9C5B5A65E9,
                                                     0xD1B526E7169AC83E, 0x0DAD5BA3BDB5F30D, 0xAF70A90042BC2A5E, 0xE55389C1D5AC115F, 0x012EFF54E3702B19,   // XPA1
                                                     0x4C987E2710131A53, 0xC85EBC0B6964FC4E, 0x01064AF42ED201FE, 0x6C7F56903B372893, 0x70D22E68DEE9FB6E, 0x41DBA2F20C3FF934,
                                                     0x741E3BC447063D35, 0x830A5DA2BB4C3381, 0x1896BD7E957480D5, 0x5FF6ABE18016BD72, 0x015B3A13274C3A5E,   // XQA0
                                                     0xAB9DA605058DB5BD, 0x676326751136B419, 0xA012ED1457E7A8FB, 0x4D2C99E2BCBDBCBF, 0x847DAAAB8AF49694, 0x57E4A8EBEE16077A,
                                                     0x253098F5145E024F, 0x2834FA2027602D7E, 0x67370BF01ECA39F5, 0xFD1988310BD8B371, 0x006E1C1994AAE711,   // XQA1
                                                     0x388557F6D513BA2E, 0x985FC6241AF2D870, 0xAB4A1A0CB162217E, 0xEFE329C716283B0C, 0x1B8A160873A72DF3, 0xE788A8E93CE9A2BF,
                                                     0x9208D779576BE635, 0x9F01542376C9CF14, 0xB4C147E4C823B27B, 0x14EBA3D4E36220A2, 0x00B5E9F1B8C6EB1F,   // XRA0
                                                     0x56DA90C58CF6CF46, 0x81618C6931E0A49F, 0xE85EDF7AAA8E245E, 0x3EFAADBA6C218FE5, 0x070BC4D671757F0A, 0x33E57D453747A238,
                                                     0xA1DE9DC8B2194C11, 0xD5C01615A266F9F3, 0x1FD965E5FB51C6F5, 0x86EA60BF172F4F54, 0x1568A2478263BE4 };  // XRA1
// Bob's generator values {XPB0, XQB0, XRB0 + XRB1*i} in GF(p697^2), expressed in Montgomery representation
const uint64_t B_gen[6*NWORDS64_FIELD]           = { 0x17004B45D6CD5264, 0x2120CCAD6F2560B1, 0x2037B4FC92D82662, 0x64A1CA7B3198E4F9, 0xA049034AC1A0019A, 0xA78FDEEA1525EFC7,
                                                     0x1235E926EB190D51, 0x20808D93DDDEB13D, 0x4EE5F74BFA19F9E7, 0xB6325316EE6D75DD, 0x016E69166BA0015E,   // XPB0
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,   // XPB1
                                                     0x6BE584AC7B4EB4F9, 0xF80F2AD8BBBEED51, 0x3681798875177782, 0x50D3F6C3774A2F09, 0xFF3C23A377640B8D, 0x6033D3DF5745A962,
                                                     0x2FF24E14C9699274, 0x83DA36836A97EB83, 0x25C8EF44B73BD1CD, 0x712062DF86ADEF09, 0x004CF039055BDB65,   // XQB0
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
                                                     0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,   // XQB1
                                                     0x94D7DFC81C1E72E5, 0xE43215CB25F12508, 0x05C2FA2D3F4AE2F9, 0xBB0752FE5CE1746B, 0xA780994FB878A14B, 0x15F6979E08C55016,
                                                     0xE520E266C3B11912, 0xA857D0496B40DA30, 0xEBACFFF0FDFA0DD2, 0x4C84A4D2485B1E15, 0x00A4F1A9A018A254,   // XRB0
                                                     0x49940C6C65957574, 0xC475B85CD816F0A5, 0x52F4C5971D1E4573, 0xE695F0CD74372CBD, 0x53BC43AA1AFA579E, 0xE02CD95D4A267AE6,
                                                     0x7B96626EBA6A4ECB, 0xF5E38B098E29F8D0, 0xEAED32068F11ACB9, 0xAFF1F42532675E47, 0x0078655255FA5626 }; // XRB1                                                     
// Montgomery constant Montgomery_R2 = (2^704)^2 mod p697
const uint64_t Montgomery_R2[NWORDS64_FIELD]     = { 0x90E8717898EB005C, 0x1DF9EB2CE3B0E597, 0x70EDDE1C2495B71C, 0x441E14E451B09CBC, 0x362ACF49015E62FF, 0x139D92FB72D960C4,
                                                     0x7840FBE341B9CCE6, 0xFC3D2E62C11AEF2F, 0xE8053C8FF2621C9B, 0x7D2E06601F8D8373, 0x01634C22A8B7316F };                                                    
// Value one in Montgomery representation 
const uint64_t Montgomery_one[NWORDS64_FIELD]    = { 0x0000000000000096, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x9A4E60E000000000,
                                                     0x2AF7E672929A5CBD, 0x6F395F62DE4B3DCF, 0xFA2387F3E390A0E9, 0xBBB4C9C22E2A84A5, 0x00C07D499880D65B };


// Fixed parameters for isogeny tree computation
const unsigned int strat_Alice[MAX_Alice-1] = { 
72, 48, 27, 15, 8, 4, 2, 1, 1, 2, 1, 1,
4, 2, 1, 1, 2, 1, 1, 7, 4, 2, 1, 1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 12, 7, 4, 2, 1,
1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 5, 3, 2, 1, 1, 1, 1, 2, 1, 1, 1, 21, 12, 7, 4, 2,
1, 1, 2, 1, 1, 3, 2, 1, 1, 1, 1, 5, 3, 2, 1, 1, 1, 1, 2, 1, 1, 1, 9, 5, 3, 2, 1,
1, 1, 1, 2, 1, 1, 1, 4, 2, 1, 1, 1, 2, 1, 1, 33, 17, 9, 5, 4, 2, 1, 1, 2, 1, 1,
2, 1, 1, 1, 4, 2, 1, 1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1,
1, 16, 8, 4, 2, 1, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 2, 1, 1,
4, 2, 1, 1, 2, 1, 1 };

const unsigned int strat_Bob[MAX_Bob-1] = { 
109, 58, 27, 12, 5, 2, 1, 1, 3, 1, 2, 1,
7, 3, 1, 2, 1, 4, 2, 1, 2, 1, 1, 15, 7, 3, 1, 2, 1, 4, 2, 1, 2, 1, 1, 8, 4, 2,
1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 31, 15, 7, 3, 1, 2, 1, 4, 2, 1, 2, 1, 1, 8, 4,
2, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 16, 8, 4, 2, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1,
1, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 58, 27, 12, 7, 3, 1, 2, 1, 4, 2,
1, 2, 1, 1, 7, 3, 1, 2, 1, 4, 2, 1, 2, 1, 1, 15, 7, 3, 1, 2, 1, 4, 2, 1, 2, 1,
1, 8, 4, 2, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 31, 15, 7, 3, 1, 2, 1, 4, 2, 1, 2,
1, 1, 8, 4, 2, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1, 16, 8, 4, 2, 1, 2, 1, 1, 4, 2,
1, 1, 2, 1, 1, 8, 4, 2, 1, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 1 };
           
// Setting up macro defines and including GF(p), GF(p^2), curve, isogeny and kex functions
#define fpcopy                        fpcopy697
#define fpzero                        fpzero697
#define fpadd                         fpadd697
#define fpsub                         fpsub697
#define fpneg                         fpneg697
#define fpdiv2                        fpdiv2_697
#define fpcorrection                  fpcorrection697
#define fpmul_mont                    fpmul697_mont
#define fpsqr_mont                    fpsqr697_mont
#define fpinv_mont                    fpinv697_mont
#define fpinv_chain_mont              fpinv697_chain_mont
#define fp2copy                       fp2copy697
#define fp2zero                       fp2zero697
#define fp2add                        fp2add697
#define fp2sub                        fp2sub697
#define mp_sub_p2                     mp_sub697_p2
#define mp_sub_p4                     mp_sub697_p4
#define sub_p4                        mp_sub_p4
#define fp2neg                        fp2neg697
#define fp2div2                       fp2div2_697
#define fp2correction                 fp2correction697
#define fp2mul_mont                   fp2mul697_mont
#define fp2sqr_mont                   fp2sqr697_mont
#define fp2inv_mont                   fp2inv697_mont
#define fp2inv_mont_ct                fp2inv697_mont_ct
#define fp2inv_mont_bingcd            fp2inv697_mont_bingcd
#define mp_add_asm                    mp_add697_asm
#define mp_subaddx2_asm               mp_subadd697x2_asm
#define mp_dblsubx2_asm               mp_dblsub697x2_asm
#define crypto_kem_keypair            crypto_kem_keypair_SIKEp697
#define crypto_kem_enc                crypto_kem_enc_SIKEp697
#define crypto_kem_dec                crypto_kem_dec_SIKEp697
#define random_mod_order_A            random_mod_order_A_SIDHp697
#define random_mod_order_B            random_mod_order_B_SIDHp697
#define EphemeralKeyGeneration_A      EphemeralKeyGeneration_A_SIDHp697
#define EphemeralKeyGeneration_B      EphemeralKeyGeneration_B_SIDHp697
#define EphemeralSecretAgreement_A    EphemeralSecretAgreement_A_SIDHp697
#define EphemeralSecretAgreement_B    EphemeralSecretAgreement_B_SIDHp697

#include "../fpx.c"
#include "../ec_isogeny.c"
#include "../sidh.c"    
#include "../sike.c"