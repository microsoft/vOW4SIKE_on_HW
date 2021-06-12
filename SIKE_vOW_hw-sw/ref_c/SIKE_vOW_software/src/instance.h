#pragma once
#include "curve_math.h"

// Instance structure
typedef struct
{
    char MODULUS[10];
    unsigned int e;
    double ALPHA;
    double BETA;
    double GAMMA;
    uint32_t PRNG_SEED;
    unsigned int NBITS_STATE;
    unsigned int NBYTES_STATE;
    unsigned int NWORDS_STATE;
    unsigned int NBITS_OVERFLOW;
    unsigned int MAX_STEPS;           // ceil(20 / THETA), where THETA = 2.25 * sqrt(w / S)
    unsigned int MAX_DIST;            // BETA * w;
    unsigned int MAX_FUNCTION_VERSIONS;
    unsigned int DIST_BOUND;          // Floor(THETA * 2^(e-1 - log(w)));
    unsigned int STRAT[LENSTRAT];
    CurveAndPointsSIDHv2 ES[2];       // Starting curve
    CurveAndPointsSIDHv2 EE;          // Ending curve
    uint64_t jinv[2*NWORDS_FIELD];    // For verifying
} instance_t;