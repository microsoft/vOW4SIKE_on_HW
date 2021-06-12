/********************************************************************************************
* AES functions 
*********************************************************************************************/

#include <assert.h>
#include <string.h>
#include "aes.h"
#include "aes_local.h"


void AES128_load_schedule(const uint8_t *key, uint8_t *schedule) {
#ifdef AES_ENABLE_NI
    aes128_load_schedule_ni(key, schedule);
#else
    aes128_load_schedule_c(key, schedule);
#endif
}


void AES128_enc(const uint8_t *plaintext, const uint8_t *schedule, uint8_t *ciphertext) {
#ifdef AES_ENABLE_NI
    aes128_enc_ni(plaintext, schedule, ciphertext);
#else
    aes128_enc_c(plaintext, schedule, ciphertext);
#endif
}

void AES128_free_schedule(uint8_t *schedule) {
    memset(schedule, 0, 16*11);
}
