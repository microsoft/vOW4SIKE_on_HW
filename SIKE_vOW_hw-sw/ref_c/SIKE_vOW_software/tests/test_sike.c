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
* Abstract: benchmarking/testing isogeny-based key encapsulation mechanism
*********************************************************************************************/ 


// Benchmark and test parameters  
#if defined(GENERIC_IMPLEMENTATION) 
    #define BENCH_LOOPS        5      // Number of iterations per bench 
    #define TEST_LOOPS         5      // Number of iterations per test
#else
    #define BENCH_LOOPS       1000       
    #define TEST_LOOPS        10      
#endif


int cryptotest_kem()
{ // Testing KEM
    unsigned int i;
    unsigned char sk[CRYPTO_SECRETKEYBYTES] = {0};
    unsigned char pk[CRYPTO_PUBLICKEYBYTES] = {0};
    unsigned char ct[CRYPTO_CIPHERTEXTBYTES] = {0};
    unsigned char ss[CRYPTO_BYTES] = {0};
    unsigned char ss_[CRYPTO_BYTES] = {0};
    bool passed = true;

    printf("\n\nTESTING ISOGENY-BASED KEY ENCAPSULATION MECHANISM %s\n", SCHEME_NAME);
    printf("--------------------------------------------------------------------------------------------------------\n\n");

    for (i = 0; i < TEST_LOOPS; i++) 
    {
        crypto_kem_keypair(pk, sk);
        crypto_kem_enc(ct, ss, pk);
        crypto_kem_dec(ss_, ct, sk);
        
        if (memcmp(ss, ss_, CRYPTO_BYTES) != 0) {
            passed = false;
            break;
        }
    }

    if (passed == true) printf("  KEM tests .................................................... PASSED");
    else { printf("  KEM tests ... FAILURE"); printf("\n"); return FAILURE; }
    printf("\n"); 

    return PASSED;
}


int cryptorun_kem()
{ // Benchmarking key exchange
    unsigned int n;
    unsigned char sk[CRYPTO_SECRETKEYBYTES] = {0};
    unsigned char pk[CRYPTO_PUBLICKEYBYTES] = {0};
    unsigned char ct[CRYPTO_CIPHERTEXTBYTES] = {0};
    unsigned char ss[CRYPTO_BYTES] = {0};
    unsigned char ss_[CRYPTO_BYTES] = {0};
    unsigned long long cycles, cycles1, cycles2;

    printf("\n\nBENCHMARKING ISOGENY-BASED KEY ENCAPSULATION MECHANISM %s\n", SCHEME_NAME);
    printf("--------------------------------------------------------------------------------------------------------\n\n");

    // Benchmarking key generation
    cycles = 0;
    for (n = 0; n < BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles();
        crypto_kem_keypair(pk, sk);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  Key generation runs in ....................................... %10lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // Benchmarking encapsulation
    cycles = 0;
    for (n = 0; n < BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles();
        crypto_kem_enc(ct, ss, pk);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  Encapsulation runs in ........................................ %10lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // Benchmarking decapsulation
    cycles = 0;
    for (n = 0; n < BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles();
        crypto_kem_dec(ss_, ct, sk);   
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  Decapsulation runs in ........................................ %10lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    return PASSED;
}


int main()
{
    int Status = PASSED;
    
    Status = cryptotest_kem();             // Test key encapsulation mechanism
    if (Status != PASSED) {
        printf("\n\n   Error detected: KEM_ERROR_SHARED_KEY \n\n");
        return FAILURE;
    }

    Status = cryptorun_kem();              // Benchmark key encapsulation mechanism
    if (Status != PASSED) {
        printf("\n\n   Error detected: KEM_ERROR_SHARED_KEY \n\n");
        return FAILURE;
    }

    return Status;
}