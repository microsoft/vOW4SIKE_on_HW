#include <stdio.h>
#include "sidh_vow_base.c"
#include "vow.c"

#ifdef XADD_LOOP_HARDWARE
#include <xADD_loop_hw.h>
#endif


// Functions for initialization

void init_stats(shared_state_t *S)
{
    // Statistics
    S->collect_vow_stats = false;  // By default don't collect stats (=> terminate run when successful)
    S->success = false;
    S->wall_time = 0.;
    S->collisions = 0;
    S->mem_collisions = 0;
    S->dist_points = 0;
    S->number_steps_collect = 0;
    S->number_steps_locate = 0;
    S->number_steps = 0;
    S->final_avg_random_functions = 0.;
}

// Functions for private state initialization

void init_private_state(shared_state_t *S, private_state_t *private_state)
{
    private_state->thread_id = 0;              // A different ID should be fixed for each core (ID beginning with 0).
    private_state->current_dist = 0;
    private_state->random_functions = 1;
    private_state->function_version = 1;

    private_state->collect_vow_stats = S->collect_vow_stats;
    private_state->collisions = 0;
    private_state->mem_collisions = 0;
    private_state->dist_points = 0;
    private_state->number_steps_collect = 0;
    private_state->number_steps_locate = 0;

    private_state->current.current_steps = 0;
    private_state->trip.current_steps = 0;

    // PRNG: initial seed could be pre-fixed in advance for each core
    XOF((unsigned char *)(&private_state->PRNG_SEED), (unsigned char *)(&insts_constants.PRNG_SEED), sizeof(private_state->PRNG_SEED), sizeof(insts_constants.PRNG_SEED), (unsigned long)private_state->thread_id + 1);
    init_prng(&private_state->prng_state, (unsigned long)private_state->PRNG_SEED);
}


// Functions to do a random function step

void SampleSIDH(private_state_t *private_state)
{ // Sample a new starting point
    sample_prng(&private_state->prng_state, (unsigned char*)private_state->current.current_state, (unsigned long)insts_constants.NBYTES_STATE);

    private_state->current.current_steps = 0;
    fix_overflow(private_state->current.current_state);
    copy_st(private_state->current.initial_state, private_state->current.current_state);
}

static void LadderThreePtSIDH(point_proj_t R, const CurveAndPointsSIDH E, const f2elm_t64* dbl_table, const unsigned char c, const unsigned char *m)
{ // Non-constant time version of LADDER3PT (ec_isogeny.c) that depends on size of m
    point_proj_t R2 = {0};
    int i, j, nbits = GetMSBSIDH(m);  // Skip top zeroes of m
    
    // Initializing points
    fp2copy(E.xpq, R2->X);
    fpcopy((digit_t*)&Montgomery_one, (digit_t*)R2->Z);
    fp2copy(E.xp, R->X);
    fpcopy((digit_t*)&Montgomery_one, (digit_t*)R->Z);
    fpzero((digit_t*)(R->Z)[1]);


#ifdef XADD_LOOP_HARDWARE

    digit_t *XQ_0 = (digit_t*)&((R->X)[0]); 
    digit_t *XQ_1 = (digit_t*)&((R->X)[1]);
    digit_t *ZQ_0 = (digit_t*)&((R->Z)[0]); 
    digit_t *ZQ_1 = (digit_t*)&((R->Z)[1]);

    digit_t *XPQ_0 = (digit_t*)&((R2->X)[0]); 
    digit_t *XPQ_1 = (digit_t*)&((R2->X)[1]);
    digit_t *ZPQ_0 = (digit_t*)&((R2->Z)[0]); 
    digit_t *ZPQ_1 = (digit_t*)&((R2->Z)[1]);

    // digit_t *XP_0;
    // digit_t *XP_1;        
    // digit_t *ZP_0;
    // digit_t *ZP_1;

    // XP_0 = (digit_t*)&(((((point_proj_t*)dbl_table)[j])->X)[0]); 
    // XP_1 = (digit_t*)&(((((point_proj_t*)dbl_table)[j])->X)[1]);
    // ZP_0 = (digit_t*)&(((((point_proj_t*)dbl_table)[j])->Z)[0]); 
    // ZP_1 = (digit_t*)&(((((point_proj_t*)dbl_table)[j])->Z)[1]);    

    // load secret key first, in words (32-bits)
    secret_key_load((uint32_t*)m, (nbits+33)/32);

    // if ((nbits+c) < 4) 
    //     printf("\nc=%d, nbits=%d\n", c, nbits);

    if (nbits | c) {

        // first function call
        xADD_hw((digit_t*)&(((((point_proj_t*)dbl_table)[0])->X)[0]), (digit_t*)&(((((point_proj_t*)dbl_table)[0])->X)[1]), (digit_t*)&(((((point_proj_t*)dbl_table)[0])->Z)[0]), (digit_t*)&(((((point_proj_t*)dbl_table)[0])->Z)[1]), XQ_0, XQ_1, ZQ_0, ZQ_1, XPQ_0, XPQ_1, ZPQ_0, ZPQ_1, 2 - c, nbits+1, 1, 0);
        
        for (j = 1; j < nbits+c-1; j++)   
        {
            xADD_hw((digit_t*)&(((((point_proj_t*)dbl_table)[j])->X)[0]), (digit_t*)&(((((point_proj_t*)dbl_table)[j])->X)[1]), (digit_t*)&(((((point_proj_t*)dbl_table)[j])->Z)[0]), (digit_t*)&(((((point_proj_t*)dbl_table)[j])->Z)[1]), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2 - c, nbits+1, 0, 0);
        }
     
        xADD_hw((digit_t*)&(((((point_proj_t*)dbl_table)[nbits+c-1])->X)[0]), (digit_t*)&(((((point_proj_t*)dbl_table)[nbits+c-1])->X)[1]), (digit_t*)&(((((point_proj_t*)dbl_table)[nbits+c-1])->Z)[0]), (digit_t*)&(((((point_proj_t*)dbl_table)[nbits+c-1])->Z)[1]), XQ_0, XQ_1, ZQ_0, ZQ_1, XPQ_0, XPQ_1, ZPQ_0, ZPQ_1, 2 - c, nbits+1, 0, 1);
    }

 

#else
    for (i = 2 - c, j = 0; i < nbits+2; i++, j++) {  // Ignore c
        if ((m[i >> 3] >> (i & 0x07)) & 1) {
            //R2->PQ, P, R->Q
            xADD(R2, ((point_proj_t*)dbl_table)[j], R->X);
            fp2mul_mont(R2->X, R->Z, R2->X);
        } else {
            //R->Q, P, R2->PQ 
            xADD(R, ((point_proj_t*)dbl_table)[j], R2->X);
            fp2mul_mont(R->X, R2->Z, R->X);
        }
    }
#endif
}

static void GetIsogeny(f2elm_t jinv, const CurveAndPointsSIDH E, const f2elm_t64* dbl_table, const unsigned char c, const unsigned char *k)
{ // Degree-2^(e/2) isogeny computation
    point_proj_t R, A24, unused1, unused2, unused3;

    // Retrieve kernel point
    LadderThreePtSIDH(R, E, dbl_table, c, k);

    fp2copy(E.a24, A24->X);
    fpcopy((digit_t *)Montgomery_one, (digit_t *)A24->Z);
    fpzero((digit_t *)(A24->Z)[1]);
        
    // Traverse tree 
    TraverseTree(jinv, R, A24->X, A24->Z, insts_constants.STRAT, LENSTRAT+1, false, unused1, unused2, unused3);

    // Frobenius
    fp2correction(jinv);
    if (jinv[1][0] & 1)
        fpneg(jinv[1]);
}

static void UpdateStSIDH(unsigned char jinvariant[FP2_ENCODED_BYTES], st_t r, const st_t s, uint32_t function_version)
{
    f2elm_t jinv;
    unsigned char c = GetC_SIDH(s);
    unsigned int index;
    CurveAndPointsSIDH* ES = (CurveAndPointsSIDH*)&insts_constants.ES;
    CurveAndPointsSIDH* EE = (CurveAndPointsSIDH*)&insts_constants.EE;

    ////// THIS IS GOING TO BE EXECUTED BY THE ACCELERATORS
    // Get the j-invariant of the corresponding curve
    if (c == 0) {
        index = (s[0] >> 1) & 1;
////////////////////////////// NOTE: THE CORE COMPUTATION TO BE HW ACCELERATED
        GetIsogeny(jinv, ES[index], (f2elm_t64*)DBL_TABLE_ES[2*(insts_constants.NBITS_STATE+1)*index], c, (unsigned char*)s);
    } else {
////////////////////////////// NOTE: THE CORE COMPUTATION TO BE HW ACCELERATED
        GetIsogeny(jinv, *EE, (f2elm_t64*)DBL_TABLE_EE, c, (unsigned char*)s);
    }
    //////////////////// RISC-V TAKES IT FROM HERE

    // Hash j into (c,b,k)
    fp2_encode(jinv, jinvariant);  // Unique encoding (includes fpcorrection)
    XOF((unsigned char*)r, jinvariant, (unsigned long)insts_constants.NBYTES_STATE, FP2_ENCODED_BYTES, (unsigned long)function_version);
    fix_overflow(r);
}

void UpdateSIDH(private_state_t *private_state)
{ // Compute random function step
    unsigned char j[FP2_ENCODED_BYTES];

    UpdateStSIDH(j, private_state->current.current_state, private_state->current.current_state, private_state->function_version);
    private_state->number_steps_collect += 1;
}

bool DistinguishedSIDH(private_state_t *private_state)
{ // Determine if it is a distinguished point
    uint32_t val;
    
    // Divide distinguishedness over interval to avoid bad cases
    val = ((uint32_t*)(private_state->current.current_state))[0] >> MEMORY_LOG_SIZE;
    val += private_state->function_version * insts_constants.DIST_BOUND;
    val &= ((1 << (insts_constants.NBITS_STATE - MEMORY_LOG_SIZE)) - 1);

    return (val <= insts_constants.DIST_BOUND);
}


// Functions for backtracking

bool BacktrackSIDH(trip_t *c0, trip_t *c1, private_state_t *private_state)
{ // Backtracking
    unsigned char jinv0[FP2_ENCODED_BYTES], jinv1[FP2_ENCODED_BYTES];
    f2elm_t jinv;
    st_t c0_, c1_;
    uint32_t L, i;

    // Make c0 have the largest number of steps
    if (c0->current_steps < c1->current_steps) {
        SwapStSIDH(c0->initial_state, c1->initial_state);
        L = c1->current_steps - c0->current_steps;
    } else {
        L = c0->current_steps - c1->current_steps;
    }

    // Catch up the trails
    for (i = 0; i < L; i++) {
        UpdateStSIDH(jinv0, c0->initial_state, c0->initial_state, private_state->function_version);
        private_state->number_steps_locate += 1;
    }

    if (is_equal_st(c0->initial_state, c1->initial_state))
        return false;  // Robin Hood

    for (i = 0; i < c1->current_steps + 1; i++) {
        UpdateStSIDH(jinv0, c0_, c0->initial_state, private_state->function_version);
        private_state->number_steps_locate += 1;
        UpdateStSIDH(jinv1, c1_, c1->initial_state, private_state->function_version);
        private_state->number_steps_locate += 1;

        if (IsEqualJinvSIDH(jinv0, jinv1)) {
            // Record collision
            private_state->collisions += 1;

            if (GetC_SIDH(c0->initial_state) == GetC_SIDH(c1->initial_state)) {
                return false;
            } else {
                fp2_decode(jinv0, jinv);
                return fp2_is_equal(jinv, (felm_t*)insts_constants.jinv);  // Return true if this is the golden collision
            }
        } else {
            copy_st(c0->initial_state, c0_);
            copy_st(c1->initial_state, c1_);
        }
    }
    // Should never reach here
    return false;
}
