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
* Abstract: benchmarking/testing isogeny-based key encapsulation mechanism SIKEp751
*********************************************************************************************/ 

#include <stdio.h>
#include <string.h>
#include "test_extras.h"
#include "../src/P751/P751_api.h"


#define SCHEME_NAME    "SIKEp751"

#define crypto_kem_keypair            crypto_kem_keypair_SIKEp751
#define crypto_kem_enc                crypto_kem_enc_SIKEp751
#define crypto_kem_dec                crypto_kem_dec_SIKEp751

#include "test_sike.c"