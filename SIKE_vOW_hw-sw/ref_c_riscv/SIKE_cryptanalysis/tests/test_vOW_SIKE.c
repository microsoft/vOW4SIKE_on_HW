/********************************************************************************************
* Testing file of the von Oorschot-Wiener (vOW) algorithm on SIKE
* Based on the SIDH and vOW4SIKE libraries
*
* Abstract: benchmarking/testing functions for van Oorschot-Wiener attack
*********************************************************************************************/

#include <stdio.h>
#include <math.h> 
#include <inttypes.h>
#include "test_extras.h"
#include "../../../ref_c/SIKE_vOW_software/src/vow.h"

#ifndef x86
#include <Murax.h>
#endif

// Greek letters
#if (OS_TARGET == OS_WIN)
#define _ALPHA_CHAR "%c", 224
#define _BETA_CHAR "%c", 225
#define _GAMMA_CHAR "%c", 226
#elif (OS_TARGET == OS_LINUX)
#include <locale.h>
#define _ALPHA_CHAR ("α")
#define _BETA_CHAR ("β")
#define _GAMMA_CHAR ("γ")
#endif


int stats_vow(bool collect_stats)
{
    uint32_t random_functions, collisions, mem_collisions, dist_points, number_steps_collect, number_steps_locate, number_steps, dist_cols;
    bool success;
 
    uint64_t cycles, cycles1, cycles2;

    shared_state_t S;

#if (OS_TARGET == OS_LINUX)
    // Set utf8 support on Linux
    setlocale(LC_ALL, "");
#endif

    printf("\nRunning vOW attack on SIKE");
    printf("\n----------------------------------------------------------------------------------------\n\n");

    success = true;
    random_functions = 0;
    collisions = 0;
    mem_collisions = 0;
    dist_points = 0;
    number_steps_collect = 0;
    number_steps_locate = 0;
    number_steps = 0;
    dist_cols = 0;
    cycles = 0;

    init_stats(&S);  // Initialize shared state
    S.collect_vow_stats = collect_stats;  

    printf("\n----------------------------------------------------------------------------------------\n");
    printf("\nInstance:\t");
    printf("e = %u\t    ", insts_constants.e);
    printf("w = %u\t", MEMORY_LOG_SIZE);
    printf(_ALPHA_CHAR);
    printf(" = %.2f\t", insts_constants.ALPHA);
    printf(_BETA_CHAR);
    printf(" = %.2f\t", insts_constants.BETA);
    printf(_GAMMA_CHAR);
    printf(" = %.2f\t", insts_constants.GAMMA);
    printf("modulus = %s", insts_constants.MODULUS);
    printf("\n\n");
    printf("Memory: \t\t\t\t\t");
    printf("RAM\n\n");
    printf("Statistics only: \t\t\t\t");
    printf("%s\n\n", collect_stats ? "Yes (only running one function version)" : "No");        
     
    cycles1 = cpucycles();
    vOW(&S);  // Attack 
    cycles2 = cpucycles();
    cycles = cycles + (cycles2 - cycles1); 

    success &= S.success;
    random_functions += (uint32_t)S.final_avg_random_functions;
    collisions += S.collisions;
    mem_collisions += S.mem_collisions;
    dist_points += S.dist_points;
    number_steps_collect += S.number_steps_collect;
    number_steps_locate += S.number_steps_locate;
    number_steps += S.number_steps;

    if (!collect_stats) {
        if (S.success)
            printf("  COMPLETE ATTACK FINISHED.");
        else
            printf("  INCOMPLETE ATTACK.");
        
        printf("\nAll tests successful: \t\t\t\t%s\n", success ? "Yes" : "No");
        printf("\n");
  
        printf("number_steps: \n");
        printf("%" PRIu32 "\n", number_steps);

        printf("number_steps_collect: \n");
        printf("%" PRIu32 "\n", number_steps_collect);

        printf("number_steps_locate: \n");
        printf("%" PRIu32 "\n", number_steps_locate);
              
        printf("random_functions: \n");
        printf("%" PRIu32 "\n", random_functions);

        printf("collisions: \n");
        printf("%" PRIu32 "\n", collisions);

    } else {     
        printf("dist_cols: \n");
        printf("%" PRIu32 "\n", dist_cols);

        printf("number_steps: \n");
        printf("%" PRIu32 "\n", number_steps);

        printf("number_steps_collect: \n");
        printf("%" PRIu32 "\n", number_steps_collect);

        printf("number_steps_locate: \n");
        printf("%" PRIu32 "\n", number_steps_locate);
              
        printf("random_functions: \n");
        printf("%" PRIu32 "\n", random_functions);

        printf("collisions: \n");
        printf("%" PRIu32 "\n", collisions);

    }
 
    printf("\n------------PERFORMANCE------------\n\n");
    printf("Total cycles for the vOW attack: %" PRIu64 "\n\n", cycles);

    return 0;
}

int main(int argc, char **argv)
{
    int Status = PASSED;
    bool collect_stats = false;  // false: full attack; true: one function round
    bool help_flag = false;
    int MAX_ARGSplus1 = 3;       // Current format: "test_vOW_SIKE -s -h"

    // Avoid output buffering
    setvbuf(stdout, NULL, _IONBF, 0);
 
    Status = stats_vow(collect_stats); // Testing
    if (Status != PASSED) {
        printf("\n\n   Error detected while running attack... \n\n");
        return 1;
    }
 
    return Status;
}
