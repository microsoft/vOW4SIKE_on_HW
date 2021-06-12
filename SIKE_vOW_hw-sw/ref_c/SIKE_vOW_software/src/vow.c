/********************************************************************************************
* Implementation of the von Oorschot-Wiener (vOW) algorithm on SIKE
* Based on the SIDH and vOW4SIKE libraries
*
* Abstract: functions for van Oorschot-Wiener attack
*********************************************************************************************/

#if !defined(HRDW)
#include <signal.h>
#endif
#include "vow.h"


static inline bool vOW_one_iteration(shared_state_t *S, private_state_t *private_state, trip_t *t, bool *success)
{ // Runs one "iteration" of vOW: sampling a point, checking for distinguishedness and possibly backtracking
  // Inputs:  S stats pointer, private_state private state pointer, t temporary triple pointer
  // Output:  success pointer: return true vOW terminated, break out of loop, 
  //                           return false keep looping

    // Walk to the next point using the current random function
    UpdateSIDH(private_state);
    private_state->current.current_steps += 1;

    // Check if the new point is distinguished
    if (DistinguishedSIDH(private_state)) {
        // Found a distinguished point. Try backtracking if unsuccessful, sample a new starting point
        digit_t id;
        bool read, res;
        private_state->current_dist++;
        private_state->dist_points++;  // S->current_dist gets reset, this doesn't
                
        // Read triple from memory
        id = MemIndexSIDH(private_state);
        read_from_memory(&private_state->trip, S, id);
        read = (private_state->trip.current_steps > 0);

        // Did not get a collision in value, hence it was just a memory address collision
        if (!read || !is_equal_st(private_state->trip.current_state, private_state->current.current_state)) {
            private_state->mem_collisions += 1;
        } else {
            // Not a simple memory collision, backtrack!
            copy_trip(t, &private_state->current);
            res = BacktrackSIDH(&private_state->trip, t, private_state);

            // Only check for success when not running for stats
            if (!private_state->collect_vow_stats) {
                if (res || *success) {  //// NOTE: I don't think success needs to be evaluated here. It is updated and evaluated before hitting this part again 
                    *success = true;
                    return true;
                }
            }
        }
        // Didn't get the golden collision, write the current distinguished point to memory and sample a new starting point
        write_to_memory(&private_state->current, S, id);
        SampleSIDH(private_state);
    }

    // Check if enough points have been mined for the current random function
    if (private_state->current_dist >= insts_constants.MAX_DIST) {
        if (private_state->collect_vow_stats)  // We are only collecting stats for one random function, can stop vOW
            return true;
        // Done with the current function version, sample a new starting point, and update the random function 
        SampleSIDH(private_state);       
        private_state->function_version++;
        private_state->random_functions++;
        private_state->current_dist = 0;
    }

    if (private_state->current.current_steps >= insts_constants.MAX_STEPS) {
        // Walked too long without finding a new distinguished point, hence sample a new starting point
        SampleSIDH(private_state);
    }
    return false;
}

#if !defined(HRDW) && (OS_TARGET == OS_LINUX)
// Handle Ctrl+C to stop prematurely and collect statistics
bool ctrl_c_pressed = false;
void sigintHandler(int sig_num)
{
    // Refer http://en.cppreference.com/w/c/program/signal
    ctrl_c_pressed = true;
}
#endif

bool vOW(shared_state_t *S)
{
    bool success = false;
    private_state_t private_state;
    trip_t t;    
    
    init_private_state(S, &private_state);

#if !defined(HRDW) && (OS_TARGET == OS_LINUX)
    // Set a Ctrl+C handler to dump statistics
    signal(SIGINT, sigintHandler);
#endif
    // While we haven't exhausted the random functions to try
    while (private_state.random_functions <= insts_constants.MAX_FUNCTION_VERSIONS && !success) {
#if !defined(HRDW) && (OS_TARGET == OS_LINUX)
        if (ctrl_c_pressed) {
            printf("\n%d: thinks ctrl+c was pressed", private_state.thread_id);
            break;
        }
#endif
        // Mine new points
        if (vOW_one_iteration(S, &private_state, &t, &success)) {
            break;
        }
    }

// Collect all the stats
    S->collisions += private_state.collisions;
    S->mem_collisions += private_state.mem_collisions;
    S->dist_points += private_state.dist_points;
    S->number_steps_collect += private_state.number_steps_collect;
    S->number_steps_locate += private_state.number_steps_locate;
    S->number_steps = S->number_steps_collect + S->number_steps_locate;
    S->final_avg_random_functions += (double)private_state.random_functions;

#if !defined(HRDW) && (OS_TARGET == OS_LINUX)
    ctrl_c_pressed = false;
#endif
    S->success = success;

    return success;
}
