/********************************************************************************************
* NEW benchmarking/testing isogeny-based key encapsulation mechanism SIKEp546
*********************************************************************************************/ 

#include <stdio.h>
#include <string.h>
#include "test_extras.h"
#include "../src/P546/P546_api.h"


#define SCHEME_NAME    "SIKEp546"

#define crypto_kem_keypair            crypto_kem_keypair_SIKEp546
#define crypto_kem_enc                crypto_kem_enc_SIKEp546
#define crypto_kem_dec                crypto_kem_dec_SIKEp546

#include "test_sike.c"