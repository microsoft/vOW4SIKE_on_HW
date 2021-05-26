/********************************************************************************************
* NEW benchmarking/testing isogeny-based key encapsulation mechanism SIKEp697
*********************************************************************************************/ 

#include <stdio.h>
#include <string.h>
#include "test_extras.h"
#include "../src/P697/P697_api.h"


#define SCHEME_NAME    "SIKEp697"

#define crypto_kem_keypair            crypto_kem_keypair_SIKEp697
#define crypto_kem_enc                crypto_kem_enc_SIKEp697
#define crypto_kem_dec                crypto_kem_dec_SIKEp697

#include "test_sike.c"