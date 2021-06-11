/********************************************************************************************
* SIDH: an efficient supersingular isogeny cryptography library 
* Copyright (c) Microsoft Corporation
*
* Website: https://github.com/microsoft/PQCrypto-SIDH
* Released under MIT license
*
* Abstract: benchmarking/testing isogeny-based key encapsulation mechanism SIKEp377
*********************************************************************************************/ 

#include <stdio.h>
#include <string.h>
#include "test_extras.h"
#include "../src/P377/P377_api.h"


#define SCHEME_NAME    "SIKEp377"

#define crypto_kem_keypair            crypto_kem_keypair_SIKEp377
#define crypto_kem_enc                crypto_kem_enc_SIKEp377
#define crypto_kem_dec                crypto_kem_dec_SIKEp377

#include "test_sike.c"