#pragma once

// Functions specific to PXXX
#ifdef P128
    #include "P128/P128_internal.h"
    extern const uint64_t Montgomery_one[NWORDS64_FIELD];
    #define fpcopy                        fpcopy128
    #define fpzero                        fpzero128
    #define fpsub                         fpsub128
    #define fpneg                         fpneg128
    #define fp2copy                       fp2copy128
    #define fp2add                        fp2add128
    #define fp2sub                        fp2sub128
    #define fp2neg                        fp2neg128
    #define fp2correction                 fp2correction128
    #define fp2mul_mont                   fp2mul128_mont
    #define fp2sqr_mont                   fp2sqr128_mont
    #define fpinv_mont                    fpinv128_mont
    #define fp2inv_mont                   fp2inv128_mont
    #define MEMORY_LOG_SIZE               9          
    #define MEMORY_SIZE                   512           // Memory limited to 32-bit, assumes that MEMORY_SIZE <= 2^RADIX
#elif defined(P377)
    #include "P377/P377_internal.h"
    extern const uint64_t Montgomery_one[NWORDS64_FIELD];
    #define fpcopy                        fpcopy377
    #define fpzero                        fpzero377
    #define fpsub                         fpsub377
    #define fpneg                         fpneg377
    #define fp2copy                       fp2copy377
    #define fp2add                        fp2add377
    #define fp2sub                        fp2sub377
    #define fp2neg                        fp2neg377
    #define fp2correction                 fp2correction377
    #define fp2mul_mont                   fp2mul377_mont
    #define fp2sqr_mont                   fp2sqr377_mont
    #define fpinv_mont                    fpinv377_mont
    #define fp2inv_mont                   fp2inv377_mont
    #define MEMORY_LOG_SIZE               10          
    #define MEMORY_SIZE                   1024          
#elif defined(P434)
    #include "P434/P434_internal.h"
    extern const uint64_t Montgomery_one[NWORDS64_FIELD];
    #define fpcopy                        fpcopy434
    #define fpzero                        fpzero434
    #define fpsub                         fpsub434
    #define fpneg                         fpneg434
    #define fp2copy                       fp2copy434
    #define fp2add                        fp2add434
    #define fp2sub                        fp2sub434
    #define fp2neg                        fp2neg434
    #define fp2correction                 fp2correction434
    #define fp2mul_mont                   fp2mul434_mont
    #define fp2sqr_mont                   fp2sqr434_mont
    #define fpinv_mont                    fpinv434_mont
    #define fp2inv_mont                   fp2inv434_mont
    #define MEMORY_LOG_SIZE               10          
    #define MEMORY_SIZE                   1024          
#elif defined(P503)
    #include "P503/P503_internal.h"
    extern const uint64_t Montgomery_one[NWORDS64_FIELD];
    #define fpcopy                        fpcopy503
    #define fpzero                        fpzero503
    #define fpsub                         fpsub503
    #define fpneg                         fpneg503
    #define fp2copy                       fp2copy503
    #define fp2add                        fp2add503
    #define fp2sub                        fp2sub503
    #define fp2neg                        fp2neg503
    #define fp2correction                 fp2correction503
    #define fp2mul_mont                   fp2mul503_mont
    #define fp2sqr_mont                   fp2sqr503_mont
    #define fpinv_mont                    fpinv503_mont
    #define fp2inv_mont                   fp2inv503_mont
    #define MEMORY_LOG_SIZE               10          
    #define MEMORY_SIZE                   1024          
#endif

typedef uint64_t f2elm_t64[2*NWORDS64_FIELD];

typedef struct {
	f2elm_t a24;
	f2elm_t xp;
	f2elm_t xq;
	f2elm_t xpq;
} CurveAndPointsSIDH;

typedef struct {
	uint64_t a24[2*NWORDS64_FIELD];
	uint64_t xp[2*NWORDS64_FIELD];
	uint64_t xq[2*NWORDS64_FIELD];
	uint64_t xpq[2*NWORDS64_FIELD];
} CurveAndPointsSIDHv2;
