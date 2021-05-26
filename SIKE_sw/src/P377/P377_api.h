/********************************************************************************************
* SIDH: an efficient supersingular isogeny cryptography library 
* Copyright (c) Microsoft Corporation
*
* Website: https://github.com/microsoft/PQCrypto-SIDH
* Released under MIT license
*
* Abstract: API header file for P377
*********************************************************************************************/  

#ifndef P377_API_H
#define P377_API_H
    

/*********************** Key encapsulation mechanism API ***********************/

#define CRYPTO_SECRETKEYBYTES     328    // MSG_BYTES + SECRETKEY_B_BYTES + CRYPTO_PUBLICKEYBYTES bytes
#define CRYPTO_PUBLICKEYBYTES     288
#define CRYPTO_BYTES               16    
#define CRYPTO_CIPHERTEXTBYTES    304    // CRYPTO_PUBLICKEYBYTES + MSG_BYTES bytes  

// Algorithm name
#define CRYPTO_ALGNAME "SIKEp377"  

// SIKE's key generation
// It produces a private key sk and computes the public key pk.
// Outputs: secret key sk (CRYPTO_SECRETKEYBYTES = 322 bytes)
//          public key pk (CRYPTO_PUBLICKEYBYTES = 288 bytes) 
int crypto_kem_keypair_SIKEp377(unsigned char *pk, unsigned char *sk);

// SIKE's encapsulation
// Input:   public key pk         (CRYPTO_PUBLICKEYBYTES = 288 bytes)
// Outputs: shared secret ss      (CRYPTO_BYTES = 10 bytes)
//          ciphertext message ct (CRYPTO_CIPHERTEXTBYTES = 298 bytes)
int crypto_kem_enc_SIKEp377(unsigned char *ct, unsigned char *ss, const unsigned char *pk);

// SIKE's decapsulation
// Input:   secret key sk         (CRYPTO_SECRETKEYBYTES = 322 bytes)
//          ciphertext message ct (CRYPTO_CIPHERTEXTBYTES = 298 bytes) 
// Outputs: shared secret ss      (CRYPTO_BYTES = 10 bytes)
int crypto_kem_dec_SIKEp377(unsigned char *ss, const unsigned char *ct, const unsigned char *sk);


// Encoding of keys for KEM-based isogeny system "SIKEp377" (wire format):
// ----------------------------------------------------------------------
// Elements over GF(p377) are encoded in 48 octets in little endian format (i.e., the least significant octet is located in the lowest memory address). 
// Elements (a+b*i) over GF(p377^2), where a and b are defined over GF(p377), are encoded as {a, b}, with a in the lowest memory portion.
//
// Private keys sk consist of the concatenation of a 10-byte random value, a value in the range [0, 2^Floor(Log(2,3^117))-1] and the public key pk. In the SIKE API, 
// private keys are encoded in 322 octets in little endian format. 
// Public keys pk consist of 3 elements in GF(p377^2). In the SIKE API, pk is encoded in 288 octets. 
// Ciphertexts ct consist of the concatenation of a public key value and a 10-byte value. In the SIKE API, ct is encoded in 288 + 10 = 298 octets.  
// Shared keys ss consist of a value of 10 octets.


/*********************** Ephemeral key exchange API ***********************/

#define SIDH_SECRETKEYBYTES_A    24
#define SIDH_SECRETKEYBYTES_B    24
#define SIDH_PUBLICKEYBYTES     288
#define SIDH_BYTES               96

// SECURITY NOTE: SIDH supports ephemeral Diffie-Hellman key exchange. It is NOT secure to use it with static keys.
// See "On the Security of Supersingular Isogeny Cryptosystems", S.D. Galbraith, C. Petit, B. Shani and Y.B. Ti, in ASIACRYPT 2010, 2010.
// Extended version available at: http://eprint.iacr.org/2010/859  

// Generation of Alice's secret key 
// Outputs random value in [0, 2^191 - 1] to be used as Alice's private key
void random_mod_order_A_SIDHp377(unsigned char* random_digits);

// Generation of Bob's secret key 
// Outputs random value in [0, 2^Floor(Log(2,3^117)) - 1] to be used as Bob's private key
void random_mod_order_B_SIDHp377(unsigned char* random_digits);

// Alice's ephemeral public key generation
// Input:  a private key PrivateKeyA in the range [0, 2^191 - 1], stored in 24 bytes. 
// Output: the public key PublicKeyA consisting of 3 GF(p377^2) elements encoded in 288 bytes.
int EphemeralKeyGeneration_A_SIDHp377(const unsigned char* PrivateKeyA, unsigned char* PublicKeyA);

// Bob's ephemeral key-pair generation
// It produces a private key PrivateKeyB and computes the public key PublicKeyB.
// The private key is an integer in the range [0, 2^Floor(Log(2,3^117)) - 1], stored in 24 bytes. 
// The public key consists of 3 GF(p377^2) elements encoded in 288 bytes.
int EphemeralKeyGeneration_B_SIDHp377(const unsigned char* PrivateKeyB, unsigned char* PublicKeyB);

// Alice's ephemeral shared secret computation
// It produces a shared secret key SharedSecretA using her secret key PrivateKeyA and Bob's public key PublicKeyB
// Inputs: Alice's PrivateKeyA is an integer in the range [0, 2^191 - 1], stored in 24 bytes. 
//         Bob's PublicKeyB consists of 3 GF(p377^2) elements encoded in 288 bytes.
// Output: a shared secret SharedSecretA that consists of one element in GF(p377^2) encoded in 96 bytes.
int EphemeralSecretAgreement_A_SIDHp377(const unsigned char* PrivateKeyA, const unsigned char* PublicKeyB, unsigned char* SharedSecretA);

// Bob's ephemeral shared secret computation
// It produces a shared secret key SharedSecretB using his secret key PrivateKeyB and Alice's public key PublicKeyA
// Inputs: Bob's PrivateKeyB is an integer in the range [0, 2^Floor(Log(2,3^117)) - 1], stored in 24 bytes. 
//         Alice's PublicKeyA consists of 3 GF(p377^2) elements encoded in 288 bytes.
// Output: a shared secret SharedSecretB that consists of one element in GF(p377^2) encoded in 96 bytes.
int EphemeralSecretAgreement_B_SIDHp377(const unsigned char* PrivateKeyB, const unsigned char* PublicKeyA, unsigned char* SharedSecretB);


// Encoding of keys for KEX-based isogeny system "SIDHp377" (wire format):
// ----------------------------------------------------------------------
// Elements over GF(p377) are encoded in 48 octets in little endian format (i.e., the least significant octet is located in the lowest memory address). 
// Elements (a+b*i) over GF(p377^2), where a and b are defined over GF(p377), are encoded as {a, b}, with a in the lowest memory portion.
//
// Private keys PrivateKeyA and PrivateKeyB can have values in the range [0, 2^191-1] and [0, 2^Floor(Log(2,3^117)) - 1], resp. In the SIDH API, 
// Alice's and Bob's private keys are encoded in 24 octets in little endian format. 
// Public keys PublicKeyA and PublicKeyB consist of 3 elements in GF(p377^2). In the SIDH API, they are encoded in 288 octets. 
// Shared keys SharedSecretA and SharedSecretB consist of one element in GF(p377^2). In the SIDH API, they are encoded in 96 octets.


#endif