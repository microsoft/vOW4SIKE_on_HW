#pragma once
#include <time.h>
#include "config.h"
#include "curve_math.h"
#include "prng.h"
#include "instance.h"

extern instance_t insts_constants;
extern f2elm_t64 DBL_TABLE_ES[], DBL_TABLE_EE[];


// Definitions for triples, shared and private states

typedef digit_t st_t[1];            // Datatype for representing a state

typedef struct
{
    uint32_t current_steps;
    st_t current_state;       /////// NOTE:  THIS IS ASSUMED 64-BIT IN THE REST OF THE CODE; TO BE FIXED
    st_t initial_state;
} trip_t;

typedef struct
{
    trip_t memory[MEMORY_SIZE];     // Memory holding triples
    // Statistics
    bool collect_vow_stats;     
    bool success;
    double wall_time;
    double total_time;
    uint32_t collisions;
    uint32_t mem_collisions;
    uint32_t dist_points;
    double final_avg_random_functions;
    uint32_t number_steps_collect;  // Counts function evaluations for collecting distinguished points
    uint32_t number_steps_locate;   // Counts function evaluations during collision locating
    uint32_t number_steps;          // Total count, the sum of the above
} shared_state_t;

typedef struct
{
    int thread_id;
    // State
    trip_t current;
    uint32_t current_dist;
    uint32_t function_version;
    uint32_t random_functions;
    // Prng
    uint32_t PRNG_SEED;
    prng_state_t prng_state;    
    // Statistics
    bool collect_vow_stats;        
    uint32_t iterations;
    uint32_t collisions;
    uint32_t mem_collisions;
    uint32_t dist_points;
    uint32_t number_steps_collect;  // Counts function evaluations for collecting distinguished points
    uint32_t number_steps_locate;   // Counts function evaluations during collision locating
    // Storage
    trip_t trip;
} private_state_t;


// Initialization functions
void init_stats(shared_state_t *S);
void init_private_state(shared_state_t *S, private_state_t *private_state);

// Functions for vOW
bool vOW(shared_state_t *S);
bool DistinguishedSIDH(private_state_t *private_state);
void SampleSIDH(private_state_t *private_state);
void UpdateSIDH(private_state_t *private_state);
bool BacktrackSIDH(trip_t *c0, trip_t *c1, private_state_t *private_state);