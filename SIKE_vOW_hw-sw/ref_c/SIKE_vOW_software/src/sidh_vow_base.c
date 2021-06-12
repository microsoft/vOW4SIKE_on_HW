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
* Abstract: utility functions (for state manipulation and memory access in vOW)
*********************************************************************************************/ 

#include "vow.h"

// Simple functions on states

static unsigned char GetC_SIDH(const st_t s)
{
    return (s[0] & 0x01);
}

static void copy_st(st_t r, const st_t s)
{
    for (unsigned int i = 0; i < insts_constants.NWORDS_STATE; i++)
        r[i] = s[i];
}

static void SwapStSIDH(st_t r, st_t s)
{
    st_t t;

    copy_st(t, r);
    copy_st(r, s);
    copy_st(s, t);
}

static bool is_equal_st(const st_t s, const st_t t)
{
    for (unsigned int i = 0; i < insts_constants.NWORDS_STATE; i++) {
        if (s[i] != t[i])
            return false;
    }
    return true;
}

static bool IsEqualJinvSIDH(unsigned char j0[FP2_ENCODED_BYTES], unsigned char j1[FP2_ENCODED_BYTES])
{
    for (unsigned int i = 0; i < FP2_ENCODED_BYTES; i++) {
        if (j0[i] != j1[i])
            return false;
    }
    return true;
}

static void copy_trip(trip_t *s, const trip_t *t)
{
    copy_st(s->current_state, t->current_state);
    s->current_steps = t->current_steps;
    copy_st(s->initial_state, t->initial_state);
}


// Functions for vOW

static digit_t MemIndexSIDH(private_state_t *private_state)
{
    // Assumes that MEMORY_SIZE <= 2^RADIX
    return (digit_t)((private_state->current.current_state[0] + private_state->random_functions) & (MEMORY_SIZE - 1));
}

static unsigned int GetMSBSIDH(const unsigned char *m)
{
    int msb = insts_constants.NBITS_STATE;
    int bit = (m[(msb - 1) >> 3] >> ((msb - 1) & 0x07)) & 1;

    while ((bit == 0) && (msb > 0)) {
        msb--;
        bit = (m[(msb - 1) >> 3] >> ((msb - 1) & 0x07)) & 1;
    }
    return msb;
}


// Functions for accessing memory

static void read_from_memory(trip_t *t, shared_state_t *S, digit_t address)
{ // Reads triple from memory at specified address
    copy_trip(t, &S->memory[address]);
}

static void write_to_memory(trip_t *t, shared_state_t *S, digit_t address)
{ // Writes triple to memory at specified address
    copy_trip(&S->memory[address], t);
}

static void fix_overflow(st_t s)
{
    ((unsigned char*)s)[insts_constants.NBYTES_STATE - 1] &= (0xFF >> (8 - insts_constants.NBITS_OVERFLOW));
}