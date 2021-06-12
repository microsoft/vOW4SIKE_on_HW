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
* Abstract: benchmarking/testing functions for van Oorschot-Wiener attack
*********************************************************************************************/

#include <stdio.h>
#include <math.h>
#include <time.h> 
#include "test_extras.h"
#include "../src/vow.h"

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
    time_t calendar_time, current_time;
    unsigned long long cycles, cycles1, cycles2;
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
    
    current_time = time(NULL);
    cycles1 = cpucycles();
    vOW(&S);  // Attack
    calendar_time = time(NULL);
    cycles2 = cpucycles();
    cycles = cycles + (cycles2 - cycles1);
    calendar_time -= current_time;

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
            printf("  COMPLETE ATTACK FINISHED using %.2f random functions and %.2f seconds", S.final_avg_random_functions, S.wall_time);
        else
            printf("  INCOMPLETE ATTACK. Used %.2f random functions and %.2f seconds", S.final_avg_random_functions, S.wall_time);
        printf("\nAll tests successful: \t\t\t\t%s\n", success ? "Yes" : "No");
        printf("\n");
        printf("Number of function iterations: \t\t%.2f (expected sqrt(n^3/w) = %.2f, ratio = %.2f)\n",
                (double)number_steps, sqrt(pow(pow(2, insts_constants.e - 1), 3) / pow(2, MEMORY_LOG_SIZE)),
                (double)number_steps / (sqrt(pow(pow(2, insts_constants.e - 1), 3) / pow(2, MEMORY_LOG_SIZE))));
        printf("\t For collecting dist. points: \t%.2f (%.2f%%)\n",
                (double)number_steps_collect, 100 * ((double)number_steps_collect / (double)number_steps));
        printf("\t For locating collisions: \t%.2f (%.2f%%)\n",
                (double)number_steps_locate, 100 * ((double)number_steps_locate / (double)number_steps));
        printf("Number of function versions: \t\t%.2f (expected 0.45n/w = %.2f, ratio = %.2f)\n",
                (double)random_functions, 0.45 * pow(2, insts_constants.e - 1) / pow(2, MEMORY_LOG_SIZE),
                (double)random_functions / (0.45 * pow(2, insts_constants.e - 1) / pow(2, MEMORY_LOG_SIZE)));
        printf("Number of collisions per function: \t%.2f (expected 1.3w = %.2f, ratio = %.2f)\n",
                ((double)collisions / (double)random_functions), 1.3 * pow(2, MEMORY_LOG_SIZE),
                (((double)collisions / (double)random_functions)) / (1.3 * pow(2, MEMORY_LOG_SIZE)));
    } else {  // If stats are collected
        printf("Number of function iterations: \t\t\t%.2f\n", (double)number_steps / (double)random_functions);
        printf("\t For collecting dist. points: \t\t%.2f (%.2f%%)\n",
                ((double)number_steps_collect / (double)random_functions), 100 * ((double)number_steps_collect / (double)number_steps));
        printf("\t For locating collisions: \t\t%.2f (%.2f%%)\n", 
                ((double)number_steps_locate / (double)random_functions), 100 * ((double)number_steps_locate / (double)number_steps));
        printf("Number of collisions per function: \t\t%.2f (expected 1.3w = %.2f, ratio = %.2f)\n", ((double)collisions / (double)random_functions),
                1.3 * pow(2, (double)MEMORY_LOG_SIZE), ((double)collisions / (double)random_functions) / (1.3 * pow(2, (double)MEMORY_LOG_SIZE)));
        printf("Number of distinct collisions per function (c): %.2f (expected 1.1w = %.2f, ratio = %.2f)\n",
                ((double)dist_cols / (double)random_functions), 1.1 * pow(2, (double)MEMORY_LOG_SIZE),
                ((double)dist_cols / (double)random_functions) / (1.1 * pow(2, (double)MEMORY_LOG_SIZE)));
        printf("\n");
        printf("Expected number of function versions (n/(2c)): \t%.2f (expected 0.45n/w = %.2f, ratio = %.2f)\n",
                pow(2, insts_constants.e - 1) / (2 * ((double)dist_cols / (double)random_functions)),
                0.45 * pow(2, insts_constants.e - 1) / pow(2, (double)MEMORY_LOG_SIZE),
                (pow(2, insts_constants.e - 1) / (2 * ((double)dist_cols / (double)random_functions))) / (0.45 * pow(2, insts_constants.e - 1) / pow(2, (double)MEMORY_LOG_SIZE)));
        printf("Expected total run-time (in/(2c)): \t\t%.2f (expected 2.5%cn^3/w = %.2f, ratio = %.2f)\n",
                ((double)number_steps / (double)random_functions) * pow(2, insts_constants.e - 1) / (2 * ((double)dist_cols / (double)random_functions)), 251,
                2.5 * sqrt(pow(pow(2, insts_constants.e - 1), 3) / pow(2, MEMORY_LOG_SIZE)),
                (((double)number_steps / (double)random_functions) * pow(2, insts_constants.e - 1) / (2 * ((double)dist_cols / (double)random_functions))) / (2.5*sqrt(pow(pow(2, insts_constants.e - 1), 3) / pow(2, MEMORY_LOG_SIZE))));
    }
    printf("\nTotal time (one core) : %ld sec\n\n", (long)calendar_time);

    return 0;
}

int main(int argc, char **argv)
{
    int Status = PASSED;
    bool collect_stats = false;  // Extra collection of stats is disabled by default
    bool help_flag = false;
    int MAX_ARGSplus1 = 3;       // Current format: "test_vOW_SIKE -s -h"

    // Avoid output buffering
    setvbuf(stdout, NULL, _IONBF, 0);

    if (argc > MAX_ARGSplus1) {
        help_flag = true;
        goto help;
    }

    for (int i = 0; i < argc - 1; i++) {
        if (argv[i + 1][0] != '-') {
            help_flag = true;
            goto help;
        }
        switch (argv[i + 1][1]) {
        case 's':
            collect_stats = true;
            break;
        case 'h':
            help_flag = true;
            break;
        default:
            help_flag = true;
            break;
        }
        if (help_flag) {
            goto help;
        }
    }

    Status = stats_vow(collect_stats); // Testing
    if (Status != PASSED) {
        printf("\n\n   Error detected while running attack... \n\n");
        return 1;
    }

help:
    if (help_flag) {
        printf("\n Usage:");
        printf("\n test_vOW_SIKE -s -h \n");
        printf("\n -s : collection of attack stats on (off by default).");
        printf("\n -h : this help.\n\n");
    }

    return Status;
}
