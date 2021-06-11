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
* Abstract: testing code for field arithmetic, elliptic curve and isogeny functions
*********************************************************************************************/

#include "../src/config.h"
#include "../src/P697/P697_internal.h"
#include "../src/internal.h"
#include "test_extras.h"
#include <stdio.h>


// Benchmark and test parameters  
#if defined(GENERIC_IMPLEMENTATION) || (TARGET == TARGET_ARM) 
    #define BENCH_LOOPS           100       // Number of iterations per bench
    #define SMALL_BENCH_LOOPS     100       // Number of iterations per bench
    #define TEST_LOOPS             10       // Number of iterations per test
#else
    #define BENCH_LOOPS        100000 
    #define SMALL_BENCH_LOOPS   10000       
    #define TEST_LOOPS            100   
#endif


bool fp_test()
{ // Tests for the field arithmetic
    bool OK = true;
    int n, passed;
    felm_t a, b, c, d, e, f, ma, mb, mc, md, me, mf;

    printf("\n--------------------------------------------------------------------------------------------------------\n\n"); 
    printf("Testing field arithmetic over GF(p697): \n\n"); 

    // Field addition over the prime p697
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fprandom697_test(a); fprandom697_test(b); fprandom697_test(c); fprandom697_test(d); fprandom697_test(e); fprandom697_test(f); 

        fpadd697(a, b, d); fpadd697(d, c, e);                 // e = (a+b)+c
        fpadd697(b, c, d); fpadd697(d, a, f);                 // f = a+(b+c)
        fpcorrection697(e);
        fpcorrection697(f);
        if (compare_words(e, f, NWORDS_FIELD)!=0) { passed=0; break; }

        fpadd697(a, b, d);                                     // d = a+b 
        fpadd697(b, a, e);                                     // e = b+a
        fpcorrection697(d);
        fpcorrection697(e);
        if (compare_words(d, e, NWORDS_FIELD)!=0) { passed=0; break; }

        fpzero697(b);
        fpadd697(a, b, d);                                     // d = a+0 
        if (compare_words(a, d, NWORDS_FIELD)!=0) { passed=0; break; }
        
        fpzero697(b);
        fpcopy697(a, d);     
        fpneg697(d);                      
        fpadd697(a, d, e);                                     // e = a+(-a)
        fpcorrection697(e);
        if (compare_words(e, b, NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p) addition tests ............................................ PASSED");
    else { printf("  GF(p) addition tests... FAILED"); printf("\n"); return false; }
    printf("\n");

    // Field subtraction over the prime p697
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fprandom697_test(a); fprandom697_test(b); fprandom697_test(c); fprandom697_test(d); fprandom697_test(e); fprandom697_test(f); 

        fpsub697(a, b, d); fpsub697(d, c, e);                 // e = (a-b)-c
        fpadd697(b, c, d); fpsub697(a, d, f);                 // f = a-(b+c)
        fpcorrection697(e);
        fpcorrection697(f);
        if (compare_words(e, f, NWORDS_FIELD)!=0) { passed=0; break; }

        fpsub697(a, b, d);                                     // d = a-b 
        fpsub697(b, a, e);                                         
        fpneg697(e);                                           // e = -(b-a)
        fpcorrection697(d);
        fpcorrection697(e);
        if (compare_words(d, e, NWORDS_FIELD)!=0) { passed=0; break; }

        fpzero697(b);
        fpsub697(a, b, d);                                     // d = a-0 
        if (compare_words(a, d, NWORDS_FIELD)!=0) { passed=0; break; }
        
        fpzero697(b);
        fpcopy697(a, d);                 
        fpsub697(a, d, e);                                     // e = a+(-a)
        fpcorrection697(e);
        if (compare_words(e, b, NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p) subtraction tests ......................................... PASSED");
    else { printf("  GF(p) subtraction tests... FAILED"); printf("\n"); return false; }
    printf("\n");

    // Field multiplication over the prime p697
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {    
        fprandom697_test(a); fprandom697_test(b); fprandom697_test(c);  
        fprandom697_test(ma); fprandom697_test(mb); fprandom697_test(mc); fprandom697_test(md); fprandom697_test(me); fprandom697_test(mf); 

        to_mont(a, ma);
        fpcopy697(ma, mc);
        from_mont(mc, c);
        if (compare_words(a, c, NWORDS_FIELD)!=0) { passed=0; break; }
        
        to_mont(a, ma); to_mont(b, mb); to_mont(c, mc); 
        fpmul697_mont(ma, mb, md); fpmul697_mont(md, mc, me);                          // e = (a*b)*c
        fpmul697_mont(mb, mc, md); fpmul697_mont(md, ma, mf);                          // f = a*(b*c)
        from_mont(me, e);
        from_mont(mf, f);
        if (compare_words(e, f, NWORDS_FIELD)!=0) { passed=0; break; }
      
        to_mont(a, ma); to_mont(b, mb); to_mont(c, mc); 
        fpadd697(mb, mc, md); fpmul697_mont(ma, md, me);                               // e = a*(b+c)
        fpmul697_mont(ma, mb, md); fpmul697_mont(ma, mc, mf); fpadd697(md, mf, mf);    // f = a*b+a*c
        from_mont(me, e);
        from_mont(mf, f);
        if (compare_words(e, f, NWORDS_FIELD)!=0) { passed=0; break; }
       
        to_mont(a, ma); to_mont(b, mb);
        fpmul697_mont(ma, mb, md);                                                      // d = a*b 
        fpmul697_mont(mb, ma, me);                                                      // e = b*a 
        from_mont(md, d);
        from_mont(me, e);
        if (compare_words(d, e, NWORDS_FIELD)!=0) { passed=0; break; }
        
        to_mont(a, ma);
        fpzero697(b); b[0] = 1; to_mont(b, mb);
        fpmul697_mont(ma, mb, md);                                                      // d = a*1  
        from_mont(ma, a);
        from_mont(md, d);                
        if (compare_words(a, d, NWORDS_FIELD)!=0) { passed=0; break; }
        
        fpzero697(b); to_mont(b, mb);
        fpmul697_mont(ma, mb, md);                                                      // d = a*0  
        from_mont(mb, b);
        from_mont(md, d);                
        if (compare_words(b, d, NWORDS_FIELD)!=0) { passed=0; break; } 
    }
    if (passed==1) printf("  GF(p) multiplication tests ...................................... PASSED");
    else { printf("  GF(p) multiplication tests... FAILED"); printf("\n"); return false; }
    printf("\n");

    // Field squaring over the prime p697
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fprandom697_test(a);
        
        to_mont(a, ma);
        fpsqr697_mont(ma, mb);                                 // b = a^2
        fpmul697_mont(ma, ma, mc);                             // c = a*a 
        if (compare_words(mb, mc, NWORDS_FIELD)!=0) { passed=0; break; }

        fpzero697(a); to_mont(a, ma);
        fpsqr697_mont(ma, md);                                 // d = 0^2 
        if (compare_words(ma, md, NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p) squaring tests............................................. PASSED");
    else { printf("  GF(p) squaring tests... FAILED"); printf("\n"); return false; }
    printf("\n");
    
    // Field inversion over the prime p697
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fprandom697_test(a); 
        to_mont(a, ma);
        fpzero697(d); d[0]=1; to_mont(d, md);
        fpcopy697(ma, mb);                            
        fpinv697_mont(ma);                                
        fpmul697_mont(ma, mb, mc);                             // c = a*a^-1 
        if (compare_words(mc, md, NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p) inversion tests............................................ PASSED");
    else { printf("  GF(p) inversion tests... FAILED"); printf("\n"); return false; }
    printf("\n");
    
    return OK;
}


bool fp2_test()
{ // Tests for the quadratic extension field arithmetic
    bool OK = true;
    int n, passed;
    f2elm_t a, b, c, d, e, f, ma, mb, mc, md, me, mf;

    printf("\n--------------------------------------------------------------------------------------------------------\n\n"); 
    printf("Testing quadratic extension arithmetic over GF(p697^2): \n\n"); 

    // Addition over GF(p697^2)
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fp2random697_test((digit_t*)a); fp2random697_test((digit_t*)b); fp2random697_test((digit_t*)c); fp2random697_test((digit_t*)d); fp2random697_test((digit_t*)e); fp2random697_test((digit_t*)f); 

        fp2add697(a, b, d); fp2add697(d, c, e);                 // e = (a+b)+c
        fp2add697(b, c, d); fp2add697(d, a, f);                 // f = a+(b+c)
        if (compare_words((digit_t*)e, (digit_t*)f, 2*NWORDS_FIELD)!=0) { passed=0; break; }

        fp2add697(a, b, d);                                     // d = a+b 
        fp2add697(b, a, e);                                     // e = b+a
        if (compare_words((digit_t*)d, (digit_t*)e, 2*NWORDS_FIELD)!=0) { passed=0; break; }

        fp2zero697(b);
        fp2add697(a, b, d);                                     // d = a+0 
        if (compare_words((digit_t*)a, (digit_t*)d, 2*NWORDS_FIELD)!=0) { passed=0; break; }
        
        fp2zero697(b);
        fp2copy697(a, d);     
        fp2neg697(d);                      
        fp2add697(a, d, e);                                     // e = a+(-a)
        if (compare_words((digit_t*)e, (digit_t*)b, 2*NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p^2) addition tests .......................................... PASSED");
    else { printf("  GF(p^2) addition tests... FAILED"); printf("\n"); return false; }
    printf("\n");

    // Subtraction over GF(p697^2)
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fp2random697_test((digit_t*)a); fp2random697_test((digit_t*)b); fp2random697_test((digit_t*)c); fp2random697_test((digit_t*)d); fp2random697_test((digit_t*)e); fp2random697_test((digit_t*)f); 

        fp2sub697(a, b, d); fp2sub697(d, c, e);                 // e = (a-b)-c
        fp2add697(b, c, d); fp2sub697(a, d, f);                 // f = a-(b+c)
        if (compare_words((digit_t*)e, (digit_t*)f, 2*NWORDS_FIELD)!=0) { passed=0; break; }

        fp2sub697(a, b, d);                                     // d = a-b 
        fp2sub697(b, a, e);                                         
        fp2neg697(e);                                           // e = -(b-a)
        if (compare_words((digit_t*)d, (digit_t*)e, 2*NWORDS_FIELD)!=0) { passed=0; break; }

        fp2zero697(b);
        fp2sub697(a, b, d);                                     // d = a-0 
        if (compare_words((digit_t*)a, (digit_t*)d, 2*NWORDS_FIELD)!=0) { passed=0; break; }
        
        fp2zero697(b);
        fp2copy697(a, d);                 
        fp2sub697(a, d, e);                                     // e = a+(-a)
        if (compare_words((digit_t*)e, (digit_t*)b, 2*NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p^2) subtraction tests ....................................... PASSED");
    else { printf("  GF(p^2) subtraction tests... FAILED"); printf("\n"); return false; }
    printf("\n");

    // Multiplication over GF(p697^2)
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {    
        fp2random697_test((digit_t*)a); fp2random697_test((digit_t*)b); fp2random697_test((digit_t*)c);  
        fp2random697_test((digit_t*)ma); fp2random697_test((digit_t*)mb); fp2random697_test((digit_t*)mc); fp2random697_test((digit_t*)md); fp2random697_test((digit_t*)me); fp2random697_test((digit_t*)mf); 

        to_fp2mont(a, ma);
        fp2copy697(ma, mc);
        from_fp2mont(mc, c);
        if (compare_words((digit_t*)a, (digit_t*)c, 2*NWORDS_FIELD)!=0) { passed=0; break; }
        
        to_fp2mont(a, ma); to_fp2mont(b, mb); to_fp2mont(c, mc); 
        fp2mul697_mont(ma, mb, md); fp2mul697_mont(md, mc, me);                          // e = (a*b)*c
        fp2mul697_mont(mb, mc, md); fp2mul697_mont(md, ma, mf);                          // f = a*(b*c)
        from_fp2mont(me, e);
        from_fp2mont(mf, f);
        if (compare_words((digit_t*)e, (digit_t*)f, 2*NWORDS_FIELD)!=0) { passed=0; break; }
      
        to_fp2mont(a, ma); to_fp2mont(b, mb); to_fp2mont(c, mc); 
        fp2add697(mb, mc, md); fp2mul697_mont(ma, md, me);                               // e = a*(b+c)
        fp2mul697_mont(ma, mb, md); fp2mul697_mont(ma, mc, mf); fp2add697(md, mf, mf);   // f = a*b+a*c
        from_fp2mont(me, e);
        from_fp2mont(mf, f);
        if (compare_words((digit_t*)e, (digit_t*)f, 2*NWORDS_FIELD)!=0) { passed=0; break; }
       
        to_fp2mont(a, ma); to_fp2mont(b, mb);
        fp2mul697_mont(ma, mb, md);                                                      // d = a*b 
        fp2mul697_mont(mb, ma, me);                                                      // e = b*a 
        from_fp2mont(md, d);
        from_fp2mont(me, e);
        if (compare_words((digit_t*)d, (digit_t*)e, 2*NWORDS_FIELD)!=0) { passed=0; break; }
        
        to_fp2mont(a, ma);
        fp2zero697(b); b[0][0] = 1; to_fp2mont(b, mb);
        fp2mul697_mont(ma, mb, md);                                                      // d = a*1  
        from_fp2mont(md, d);               
        if (compare_words((digit_t*)a, (digit_t*)d, 2*NWORDS_FIELD)!=0) { passed=0; break; }
        
        fp2zero697(b); to_fp2mont(b, mb);
        fp2mul697_mont(ma, mb, md);                                                      // d = a*0 
        from_fp2mont(md, d);               
        if (compare_words((digit_t*)b, (digit_t*)d, 2*NWORDS_FIELD)!=0) { passed=0; break; } 
    }
    if (passed==1) printf("  GF(p^2) multiplication tests .................................... PASSED");
    else { printf("  GF(p^2) multiplication tests... FAILED"); printf("\n"); return false; }
    printf("\n");

    // Squaring over GF(p697^2)
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fp2random697_test((digit_t*)a);
        
        to_fp2mont(a, ma);
        fp2sqr697_mont(ma, mb);                                 // b = a^2
        fp2mul697_mont(ma, ma, mc);                             // c = a*a 
        from_fp2mont(mb, b);               
        from_fp2mont(mc, c);               
        if (compare_words((digit_t*)b, (digit_t*)c, 2*NWORDS_FIELD)!=0) { passed=0; break; }

        fp2zero697(a); to_fp2mont(a, ma);
        fp2sqr697_mont(ma, md);                                 // d = 0^2 
        from_fp2mont(md, d);               
        if (compare_words((digit_t*)a, (digit_t*)d, 2*NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p^2) squaring tests........................................... PASSED");
    else { printf("  GF(p^2) squaring tests... FAILED"); printf("\n"); return false; }
    printf("\n");
    
    // Inversion over GF(p697^2)
    passed = 1;
    for (n=0; n<TEST_LOOPS; n++)
    {
        fp2random697_test((digit_t*)a);    
        
        to_fp2mont(a, ma);
        fp2zero697(d); d[0][0]=1; to_fp2mont(d, md);
        fp2copy697(ma, mb);                            
        fp2inv697_mont(ma);                                
        fp2mul697_mont(ma, mb, mc);                             // c = a*a^-1              
        from_fp2mont(mc, c);  
        if (compare_words((digit_t*)c, (digit_t*)d, 2*NWORDS_FIELD)!=0) { passed=0; break; }
    }
    if (passed==1) printf("  GF(p^2) inversion tests.......................................... PASSED");
    else { printf("  GF(p^2) inversion tests... FAILED"); printf("\n"); return false; }
    printf("\n");
    
    return OK;
}


bool fp_run()
{
    bool OK = true;
    int n;
    unsigned long long cycles, cycles1, cycles2;
    felm_t a, b, c;
    dfelm_t aa;
        
    printf("\n--------------------------------------------------------------------------------------------------------\n\n"); 
    printf("Benchmarking field arithmetic over GF(p697): \n\n"); 
        
    fprandom697_test(a); fprandom697_test(b); fprandom697_test(c);

    // GF(p) addition using p697
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fpadd697(a, b, c);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p) addition runs in .......................................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p) subtraction using p697
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fpsub697(a, b, c);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p) subtraction runs in ....................................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p) multiplication using p697
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fpmul697_mont(a, b, c);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p) multiplication runs in .................................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p) reduction using p697
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        mp_mul(a, b, aa, NWORDS_FIELD);

        cycles1 = cpucycles(); 
        rdc_mont(aa, c);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p) reduction runs in ......................................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p) inversion
    cycles = 0;
    for (n=0; n<SMALL_BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fpinv697_mont(a);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p) inversion (exponentiation) runs in ........................ %7lld ", cycles/SMALL_BENCH_LOOPS); print_unit;
    printf("\n"); 
    
    return OK;
}


bool fp2_run()
{
    bool OK = true;
    int n;
    unsigned long long cycles, cycles1, cycles2;
    f2elm_t a, b, c;
        
    printf("\n--------------------------------------------------------------------------------------------------------\n\n"); 
    printf("Benchmarking quadratic extension arithmetic over GF(p697^2): \n\n"); 
    
    fp2random697_test((digit_t*)a); fp2random697_test((digit_t*)b); fp2random697_test((digit_t*)c);

    // GF(p^2) addition
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fp2add697(a, b, c);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p^2) addition runs in ........................................ %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p^2) subtraction
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fp2sub697(a, b, c);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p^2) subtraction runs in ..................................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p^2) multiplication
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fp2mul697_mont(a, b, c);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p^2) multiplication runs in .................................. %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p^2) squaring
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fp2sqr697_mont(a, b);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p^2) squaring runs in ........................................ %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // GF(p^2) inversion
    cycles = 0;
    for (n=0; n<SMALL_BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        fp2inv697_mont(a);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  GF(p^2) inversion (exponentiation) runs in ...................... %7lld ", cycles/SMALL_BENCH_LOOPS); print_unit;
    printf("\n");
    
    return OK;
}


bool ecisog_run()
{
    bool OK = true;
    int n;
    unsigned long long cycles, cycles1, cycles2;
    f2elm_t A24, C24, A4, A, C, coeff[5];
    point_proj_t P, Q;
        
    printf("\n--------------------------------------------------------------------------------------------------------\n\n"); 
    printf("Benchmarking elliptic curve and isogeny functions: \n\n"); 

    // Point doubling
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        fp2random697_test((digit_t*)A24); fp2random697_test((digit_t*)C24);

        cycles1 = cpucycles(); 
        xDBL(P, Q, A24, C24);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  Point doubling runs in .......................................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // 4-isogeny of a projective point
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        fp2random697_test((digit_t*)A); fp2random697_test((digit_t*)coeff[0]); fp2random697_test((digit_t*)coeff[1]); fp2random697_test((digit_t*)coeff[2]);

        cycles1 = cpucycles(); 
        get_4_isog(P, A, C, coeff);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  4-isogeny of projective point runs in ........................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // 4-isogeny evaluation at projective point
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        fp2random697_test((digit_t*)A); fp2random697_test((digit_t*)coeff[0]); fp2random697_test((digit_t*)coeff[1]); fp2random697_test((digit_t*)coeff[2]);

        cycles1 = cpucycles(); 
        eval_4_isog(P, coeff);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  4-isogeny evaluation at projective point runs in ................ %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // Point tripling
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        fp2random697_test((digit_t*)A4); fp2random697_test((digit_t*)C);

        cycles1 = cpucycles(); 
        xTPL(P, Q, A4, C);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  Point tripling runs in .......................................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // 3-isogeny of a projective point
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        fp2random697_test((digit_t*)A); fp2random697_test((digit_t*)C);

        cycles1 = cpucycles(); 
        get_3_isog(P, A, C, coeff);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  3-isogeny of projective point runs in ........................... %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");

    // 3-isogeny evaluation at projective point
    cycles = 0;
    for (n=0; n<BENCH_LOOPS; n++)
    {
        cycles1 = cpucycles(); 
        eval_3_isog(Q, coeff);
        cycles2 = cpucycles();
        cycles = cycles+(cycles2-cycles1);
    }
    printf("  3-isogeny evaluation at projective point runs in ................ %7lld ", cycles/BENCH_LOOPS); print_unit;
    printf("\n");
    
    return OK;
}


int main()
{
    bool OK = true;

    OK = OK && fp_test();          // Test field operations using p697
    OK = OK && fp_run();           // Benchmark field operations using p697

    OK = OK && fp2_test();         // Test arithmetic functions over GF(p697^2)
    OK = OK && fp2_run();          // Benchmark arithmetic functions over GF(p697^2)
    
    OK = OK && ecisog_run();       // Benchmark elliptic curve and isogeny functions

    return OK;
}
