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
* Abstract: elliptic curve and isogeny functions
*********************************************************************************************/
#ifdef XDBLE_HARDWARE
#include <xDBLe_hw.h>
#endif

#ifdef GET_4_ISOG_AND_EVAL_4_ISOG_HARDWARE
#include <get_4_isog_and_eval_4_isog_hw.h>
#endif

void xDBL(const point_proj_t P, point_proj_t Q, const f2elm_t A24plus, const f2elm_t C24)
{ // Doubling of a Montgomery point in projective coordinates (X:Z).
  // Input: projective Montgomery x-coordinates P = (X1:Z1), where x1=X1/Z1 and Montgomery curve constants A+2C and 4C.
  // Output: projective Montgomery x-coordinates Q = 2*P = (X2:Z2).
    f2elm_t t0, t1;
    
    mp2_sub_p2(P->X, P->Z, t0);                     // t0 = X1-Z1
    mp2_add(P->X, P->Z, t1);                        // t1 = X1+Z1
    fp2sqr_mont(t0, t0);                            // t0 = (X1-Z1)^2 
    fp2sqr_mont(t1, t1);                            // t1 = (X1+Z1)^2 
    fp2mul_mont(C24, t0, Q->Z);                     // Z2 = C24*(X1-Z1)^2   
    fp2mul_mont(t1, Q->Z, Q->X);                    // X2 = C24*(X1-Z1)^2*(X1+Z1)^2
    mp2_sub_p2(t1, t0, t1);                         // t1 = (X1+Z1)^2-(X1-Z1)^2 
    fp2mul_mont(A24plus, t1, t0);                   // t0 = A24plus*[(X1+Z1)^2-(X1-Z1)^2]
    mp2_add(Q->Z, t0, Q->Z);                        // Z2 = A24plus*[(X1+Z1)^2-(X1-Z1)^2] + C24*(X1-Z1)^2
    fp2mul_mont(Q->Z, t1, Q->Z);                    // Z2 = [A24plus*[(X1+Z1)^2-(X1-Z1)^2] + C24*(X1-Z1)^2]*[(X1+Z1)^2-(X1-Z1)^2]
}


void xDBLe(const point_proj_t P, point_proj_t Q, const f2elm_t A24plus, const f2elm_t C24, const int e)
{ // Computes [2^e](X:Z) on Montgomery curve with projective constant via e repeated doublings.
  // Input: projective Montgomery x-coordinates P = (XP:ZP), such that xP=XP/ZP and Montgomery curve constants A+2C and 4C.
  // Output: projective Montgomery x-coordinates Q <- (2^e)*P.
#ifdef XDBLE_HARDWARE 
 
    xDBLe_hw((digit_t*)&((P->X)[0]), 
             (digit_t*)&((P->X)[1]), 
             (digit_t*)&((P->Z)[0]), 
             (digit_t*)&((P->Z)[1]), 
             (digit_t*)&((Q->X)[0]), 
             (digit_t*)&((Q->X)[1]), 
             (digit_t*)&((Q->Z)[0]), 
             (digit_t*)&((Q->Z)[1]), 
             (digit_t*)&(A24plus[0]), 
             (digit_t*)&(A24plus[1]), 
             (digit_t*)&(C24[0]), 
             (digit_t*)&(C24[1]), e); 
#else
    int i;
    
    copy_words((digit_t*)P, (digit_t*)Q, 2*2*NWORDS_FIELD);

    for (i = 0; i < e; i++) {
        xDBL(Q, Q, A24plus, C24);
    }
#endif
}

#if (OALICE_BITS % 2 == 1)

void get_2_isog(const point_proj_t P, f2elm_t A, f2elm_t C)
{ // Computes the corresponding 2-isogeny of a projective Montgomery point (X2:Z2) of order 2.
  // Input:  projective point of order two P = (X2:Z2).
  // Output: the 2-isogenous Montgomery curve with projective coefficients A/C.

    fp2sqr_mont(P->X, A);                           // A = X2^2   /* parallel 1 */
    fp2sqr_mont(P->Z, C);                           // C = Z2^2   /* parallel 1 */
    mp2_sub_p2(C, A, A);                            // A = Z2^2 - X2^2
}


void eval_2_isog(point_proj_t P, point_proj_t Q)
{ // Evaluates the isogeny at the point (X:Z) in the domain of the isogeny, given a 2-isogeny phi.
  // Inputs: the projective point P = (X:Z) and the 2-isogeny kernel projetive point Q = (X2:Z2).
  // Output: the projective point P = phi(P) = (X:Z) in the codomain. 
    f2elm_t t0, t1, t2, t3;    

    mp2_add(Q->X, Q->Z, t0);                        // t0 = X2+Z2
    mp2_sub_p2(Q->X, Q->Z, t1);                     // t1 = X2-Z2
    mp2_add(P->X, P->Z, t2);                        // t2 = X+Z
    mp2_sub_p2(P->X, P->Z, t3);                     // t3 = X-Z
    fp2mul_mont(t0, t3, t0);                        // t0 = (X2+Z2)*(X-Z)   /* parallel 1 */
    fp2mul_mont(t1, t2, t1);                        // t1 = (X2-Z2)*(X+Z)   /* parallel 1 */
    mp2_add(t0, t1, t2);                            // t2 = (X2+Z2)*(X-Z) + (X2-Z2)*(X+Z)   
    mp2_sub_p2(t0, t1, t3);                         // t3 = (X2+Z2)*(X-Z) - (X2-Z2)*(X+Z)
    fp2mul_mont(P->X, t2, P->X);                    // Xfinal   /* parallel 2 */
    fp2mul_mont(P->Z, t3, P->Z);                    // Zfinal   /* parallel 2 */
}

#endif

void get_4_isog(const point_proj_t P, f2elm_t A24plus, f2elm_t C24, f2elm_t* coeff)
{ // Computes the corresponding 4-isogeny of a projective Montgomery point (X4:Z4) of order 4.
  // Input:  projective point of order four P = (X4:Z4).
  // Output: the 4-isogenous Montgomery curve with projective coefficients A+2C/4C and the 3 coefficients 
  //         that are used to evaluate the isogeny at a point in eval_4_isog().
    mp2_sub_p2(P->X, P->Z, coeff[1]);               // coeff[1] = X4-Z4
    mp2_add(P->X, P->Z, coeff[2]);                  // coeff[2] = X4+Z4
    fp2sqr_mont(P->Z, coeff[0]);                    // coeff[0] = Z4^2
    mp2_add(coeff[0], coeff[0], coeff[0]);          // coeff[0] = 2*Z4^2
    fp2sqr_mont(coeff[0], C24);                     // C24 = 4*Z4^4
    mp2_add(coeff[0], coeff[0], coeff[0]);          // coeff[0] = 4*Z4^2
    fp2sqr_mont(P->X, A24plus);                     // A24plus = X4^2
    mp2_add(A24plus, A24plus, A24plus);             // A24plus = 2*X4^2
    fp2sqr_mont(A24plus, A24plus);                  // A24plus = 4*X4^4
}


void eval_4_isog(point_proj_t P, f2elm_t* coeff)
{ // Evaluates the isogeny at the point (X:Z) in the domain of the isogeny, given a 4-isogeny phi defined 
  // by the 3 coefficients in coeff (computed in the function get_4_isog()).
  // Inputs: the coefficients defining the isogeny, and the projective point P = (X:Z).
  // Output: the projective point P = phi(P) = (X:Z) in the codomain.
    f2elm_t t0, t1;
    
    mp2_add(P->X, P->Z, t0);                        // t0 = X+Z
    mp2_sub_p2(P->X, P->Z, t1);                     // t1 = X-Z
    fp2mul_mont(t0, coeff[1], P->X);                // X = (X+Z)*coeff[1]
    fp2mul_mont(t1, coeff[2], P->Z);                // Z = (X-Z)*coeff[2]
    fp2mul_mont(t0, t1, t0);                        // t0 = (X+Z)*(X-Z)
    fp2mul_mont(coeff[0], t0, t0);                  // t0 = coeff[0]*(X+Z)*(X-Z)
    mp2_add(P->X, P->Z, t1);                        // t1 = (X-Z)*coeff[2] + (X+Z)*coeff[1]
    mp2_sub_p2(P->X, P->Z, P->Z);                   // Z = (X-Z)*coeff[2] - (X+Z)*coeff[1]
    fp2sqr_mont(t1, t1);                            // t1 = [(X-Z)*coeff[2] + (X+Z)*coeff[1]]^2
    fp2sqr_mont(P->Z, P->Z);                        // Z = [(X-Z)*coeff[2] - (X+Z)*coeff[1]]^2
    mp2_add(t1, t0, P->X);                          // X = coeff[0]*(X+Z)*(X-Z) + [(X-Z)*coeff[2] + (X+Z)*coeff[1]]^2
    mp2_sub_p2(P->Z, t0, t0);                       // t0 = [(X-Z)*coeff[2] - (X+Z)*coeff[1]]^2 - coeff[0]*(X+Z)*(X-Z)
    fp2mul_mont(P->X, t1, P->X);                    // Xfinal
    fp2mul_mont(P->Z, t0, P->Z);                    // Zfinal
}


void xTPL(const point_proj_t P, point_proj_t Q, const f2elm_t A24minus, const f2elm_t A24plus)              
{ // Tripling of a Montgomery point in projective coordinates (X:Z).
  // Input: projective Montgomery x-coordinates P = (X:Z), where x=X/Z and Montgomery curve constants A24plus = A+2C and A24minus = A-2C.
  // Output: projective Montgomery x-coordinates Q = 3*P = (X3:Z3).
    f2elm_t t0, t1, t2, t3, t4, t5, t6;
                                    
    mp2_sub_p2(P->X, P->Z, t0);                     // t0 = X-Z 
    fp2sqr_mont(t0, t2);                            // t2 = (X-Z)^2           
    mp2_add(P->X, P->Z, t1);                        // t1 = X+Z 
    fp2sqr_mont(t1, t3);                            // t3 = (X+Z)^2
    mp2_add(P->X, P->X, t4);                        // t4 = 2*X
    mp2_add(P->Z, P->Z, t0);                        // t0 = 2*Z 
    fp2sqr_mont(t4, t1);                            // t1 = 4*X^2
    mp2_sub_p2(t1, t3, t1);                         // t1 = 4*X^2 - (X+Z)^2 
    mp2_sub_p2(t1, t2, t1);                         // t1 = 4*X^2 - (X+Z)^2 - (X-Z)^2
    fp2mul_mont(A24plus, t3, t5);                   // t5 = A24plus*(X+Z)^2 
    fp2mul_mont(t3, t5, t3);                        // t3 = A24plus*(X+Z)^4
    fp2mul_mont(A24minus, t2, t6);                  // t6 = A24minus*(X-Z)^2
    fp2mul_mont(t2, t6, t2);                        // t2 = A24minus*(X-Z)^4
    mp2_sub_p2(t2, t3, t3);                         // t3 = A24minus*(X-Z)^4 - A24plus*(X+Z)^4
    mp2_sub_p2(t5, t6, t2);                         // t2 = A24plus*(X+Z)^2 - A24minus*(X-Z)^2
    fp2mul_mont(t1, t2, t1);                        // t1 = [4*X^2 - (X+Z)^2 - (X-Z)^2]*[A24plus*(X+Z)^2 - A24minus*(X-Z)^2]
    fp2add(t3, t1, t2);                             // t2 = [4*X^2 - (X+Z)^2 - (X-Z)^2]*[A24plus*(X+Z)^2 - A24minus*(X-Z)^2] + A24minus*(X-Z)^4 - A24plus*(X+Z)^4
    fp2sqr_mont(t2, t2);                            // t2 = t2^2
    fp2mul_mont(t4, t2, Q->X);                      // X3 = 2*X*t2
    fp2sub(t3, t1, t1);                             // t1 = A24minus*(X-Z)^4 - A24plus*(X+Z)^4 - [4*X^2 - (X+Z)^2 - (X-Z)^2]*[A24plus*(X+Z)^2 - A24minus*(X-Z)^2]
    fp2sqr_mont(t1, t1);                            // t1 = t1^2
    fp2mul_mont(t0, t1, Q->Z);                      // Z3 = 2*Z*t1
}


void xTPLe(const point_proj_t P, point_proj_t Q, const f2elm_t A24minus, const f2elm_t A24plus, const int e)
{ // Computes [3^e](X:Z) on Montgomery curve with projective constant via e repeated triplings.
  // Input: projective Montgomery x-coordinates P = (XP:ZP), such that xP=XP/ZP and Montgomery curve constants A24plus = A+2C and A24minus = A-2C.
  // Output: projective Montgomery x-coordinates Q <- (3^e)*P.
    int i;
        
    copy_words((digit_t*)P, (digit_t*)Q, 2*2*NWORDS_FIELD);

    for (i = 0; i < e; i++) {
        xTPL(Q, Q, A24minus, A24plus);
    }
}


void get_3_isog(const point_proj_t P, f2elm_t A24minus, f2elm_t A24plus, f2elm_t* coeff)
{ // Computes the corresponding 3-isogeny of a projective Montgomery point (X3:Z3) of order 3.
  // Input:  projective point of order three P = (X3:Z3).
  // Output: the 3-isogenous Montgomery curve with projective coefficient A/C. 
    f2elm_t t0, t1, t2, t3, t4;
    
    mp2_sub_p2(P->X, P->Z, coeff[0]);               // coeff0 = X-Z
    fp2sqr_mont(coeff[0], t0);                      // t0 = (X-Z)^2
    mp2_add(P->X, P->Z, coeff[1]);                  // coeff1 = X+Z
    fp2sqr_mont(coeff[1], t1);                      // t1 = (X+Z)^2
    mp2_add(P->X, P->X, t3);                        // t3 = 2*X
    fp2sqr_mont(t3, t3);                            // t3 = 4*X^2 
    fp2sub(t3, t0, t2);                             // t2 = 4*X^2 - (X-Z)^2 
    fp2sub(t3, t1, t3);                             // t3 = 4*X^2 - (X+Z)^2
    mp2_add(t0, t3, t4);                            // t4 = 4*X^2 - (X+Z)^2 + (X-Z)^2 
    mp2_add(t4, t4, t4);                            // t4 = 2(4*X^2 - (X+Z)^2 + (X-Z)^2) 
    mp2_add(t1, t4, t4);                            // t4 = 8*X^2 - (X+Z)^2 + 2*(X-Z)^2
    fp2mul_mont(t2, t4, A24minus);                  // A24minus = [4*X^2 - (X-Z)^2]*[8*X^2 - (X+Z)^2 + 2*(X-Z)^2]
    mp2_add(t1, t2, t4);                            // t4 = 4*X^2 + (X+Z)^2 - (X-Z)^2
    mp2_add(t4, t4, t4);                            // t4 = 2(4*X^2 + (X+Z)^2 - (X-Z)^2) 
    mp2_add(t0, t4, t4);                            // t4 = 8*X^2 + 2*(X+Z)^2 - (X-Z)^2
    fp2mul_mont(t3, t4, A24plus);                   // A24plus = [4*X^2 - (X+Z)^2]*[8*X^2 + 2*(X+Z)^2 - (X-Z)^2]
}


void eval_3_isog(point_proj_t Q, const f2elm_t* coeff)
{ // Computes the 3-isogeny R=phi(X:Z), given projective point (X3:Z3) of order 3 on a Montgomery curve and 
  // a point P with 2 coefficients in coeff (computed in the function get_3_isog()).
  // Inputs: projective points P = (X3:Z3) and Q = (X:Z).
  // Output: the projective point Q <- phi(Q) = (X3:Z3).
    f2elm_t t0, t1, t2;
     
    mp2_add(Q->X, Q->Z, t0);                      // t0 = X+Z
    mp2_sub_p2(Q->X, Q->Z, t1);                   // t1 = X-Z
    fp2mul_mont(coeff[0], t0, t0);                // t0 = coeff0*(X+Z)   /* parallel 1 */
    fp2mul_mont(coeff[1], t1, t1);                // t1 = coeff1*(X-Z)   /* parallel 1 */
    mp2_add(t0, t1, t2);                          // t2 = coeff0*(X+Z) + coeff1*(X-Z)
    mp2_sub_p2(t1, t0, t0);                       // t0 = coeff1*(X-Z) - coeff0*(X+Z)
    fp2sqr_mont(t2, t2);                          // t2 = [coeff0*(X+Z) + coeff1*(X-Z)]^2    /* parallel 2 */
    fp2sqr_mont(t0, t0);                          // t0 = [coeff1*(X-Z) - coeff0*(X+Z)]^2    /* parallel 2 */
    fp2mul_mont(Q->X, t2, Q->X);                  // X3final = X*[coeff0*(X+Z) + coeff1*(X-Z)]^2   /* parallel 3 */     
    fp2mul_mont(Q->Z, t0, Q->Z);                  // Z3final = Z*[coeff1*(X-Z) - coeff0*(X+Z)]^2   /* parallel 3 */
}


void inv_3_way(f2elm_t z1, f2elm_t z2, f2elm_t z3)
{ // 3-way simultaneous inversion
  // Input:  z1,z2,z3
  // Output: 1/z1,1/z2,1/z3 (override inputs).
    f2elm_t t0, t1, t2;

    fp2mul_mont(z1, z2, t0);                      // t0 = z1*z2         /* serial */
    fp2mul_mont(z3, t0, t1);                      // t1 = z1*z2*z3      /* serial */
    fp2inv_mont_ct(t1);                           // t1 = 1/(z1*z2*z3)
    fp2mul_mont(z3, t1, t2);                      // t2 = 1/(z1*z2)     /* parallel 1 */
    fp2mul_mont(t0, t1, z3);                      // z3 = 1/z3          /* parallel 1 */
    fp2mul_mont(t2, z2, t0);                      // z1 = 1/z1          /* parallel 2 */
    fp2mul_mont(t2, z1, z2);                      // z2 = 1/z2          /* parallel 2 */
    fp2copy(t0, z1);
}


void get_A(const f2elm_t xP, const f2elm_t xQ, const f2elm_t xR, f2elm_t A)
{ // Given the x-coordinates of P, Q, and R, returns the value A corresponding to the Montgomery curve E_A: y^2=x^3+A*x^2+x such that R=Q-P on E_A.
  // Input:  the x-coordinates xP, xQ, and xR of the points P, Q and R.
  // Output: the coefficient A corresponding to the curve E_A: y^2=x^3+A*x^2+x.
    f2elm_t t0, t1, one = {0};
    
    fpcopy((digit_t*)&Montgomery_one, one[0]);
    fp2add(xP, xQ, t1);                           // t1 = xP+xQ
    fp2mul_mont(xP, xQ, t0);                      // t0 = xP*xQ
    fp2mul_mont(xR, t1, A);                       // A = xR*t1
    fp2add(t0, A, A);                             // A = A+t0
    fp2mul_mont(t0, xR, t0);                      // t0 = t0*xR
    fp2sub(A, one, A);                            // A = A-1
    fp2add(t0, t0, t0);                           // t0 = t0+t0
    fp2add(t1, xR, t1);                           // t1 = t1+xR
    fp2add(t0, t0, t0);                           // t0 = t0+t0
    fp2sqr_mont(A, A);                            // A = A^2
    fp2inv_mont(t0);                              // t0 = 1/t0
    fp2mul_mont(A, t0, A);                        // A = A*t0
    fp2sub(A, t1, A);                             // Afinal = A-t1
}


void j_inv(const f2elm_t A, const f2elm_t C, f2elm_t jinv)
{ // Computes the j-invariant of a Montgomery curve with projective constant.
  // Input: A,C in GF(p^2).
  // Output: j=256*(A^2-3*C^2)^3/(C^4*(A^2-4*C^2)), which is the j-invariant of the Montgomery curve B*y^2=x^3+(A/C)*x^2+x or (equivalently) j-invariant of B'*y^2=C*x^3+A*x^2+C*x. 
    f2elm_t t0, t1;
    
    fp2sqr_mont(A, jinv);                           // jinv = A^2        
    fp2sqr_mont(C, t1);                             // t1 = C^2
    fp2add(t1, t1, t0);                             // t0 = t1+t1
    fp2sub(jinv, t0, t0);                           // t0 = jinv-t0
    fp2sub(t0, t1, t0);                             // t0 = t0-t1
    fp2sub(t0, t1, jinv);                           // jinv = t0-t1
    fp2sqr_mont(t1, t1);                            // t1 = t1^2
    fp2mul_mont(jinv, t1, jinv);                    // jinv = jinv*t1
    fp2add(t0, t0, t0);                             // t0 = t0+t0
    fp2add(t0, t0, t0);                             // t0 = t0+t0
    fp2sqr_mont(t0, t1);                            // t1 = t0^2
    fp2mul_mont(t0, t1, t0);                        // t0 = t0*t1
    fp2add(t0, t0, t0);                             // t0 = t0+t0
    fp2add(t0, t0, t0);                             // t0 = t0+t0
    fp2inv_mont(jinv);                              // jinv = 1/jinv 
    fp2mul_mont(jinv, t0, jinv);                    // jinv = t0*jinv
}


void xDBLADD(point_proj_t P, point_proj_t Q, const f2elm_t xPQ, const f2elm_t A24)
{ // Simultaneous doubling and differential addition.
  // Input: projective Montgomery points P=(XP:ZP) and Q=(XQ:ZQ) such that xP=XP/ZP and xQ=XQ/ZQ, affine difference xPQ=x(P-Q) and Montgomery curve constant A24=(A+2)/4.
  // Output: projective Montgomery points P <- 2*P = (X2P:Z2P) such that x(2P)=X2P/Z2P, and Q <- P+Q = (XQP:ZQP) such that = x(Q+P)=XQP/ZQP.
    f2elm_t t0, t1, t2;

    mp2_add(P->X, P->Z, t0);                        // t0 = XP+ZP
    mp2_sub_p2(P->X, P->Z, t1);                     // t1 = XP-ZP
    fp2sqr_mont(t0, P->X);                          // XP = (XP+ZP)^2
    mp2_sub_p2(Q->X, Q->Z, t2);                     // t2 = XQ-ZQ
    mp2_add(Q->X, Q->Z, Q->X);                      // XQ = XQ+ZQ
    fp2mul_mont(t0, t2, t0);                        // t0 = (XP+ZP)*(XQ-ZQ)
    fp2sqr_mont(t1, P->Z);                          // ZP = (XP-ZP)^2
    fp2mul_mont(t1, Q->X, t1);                      // t1 = (XP-ZP)*(XQ+ZQ)
    mp2_sub_p2(P->X, P->Z, t2);                     // t2 = (XP+ZP)^2-(XP-ZP)^2
    fp2mul_mont(P->X, P->Z, P->X);                  // XP = (XP+ZP)^2*(XP-ZP)^2
    fp2mul_mont(A24, t2, Q->X);                     // XQ = A24*[(XP+ZP)^2-(XP-ZP)^2]
    mp2_sub_p2(t0, t1, Q->Z);                       // ZQ = (XP+ZP)*(XQ-ZQ)-(XP-ZP)*(XQ+ZQ)
    mp2_add(Q->X, P->Z, P->Z);                      // ZP = A24*[(XP+ZP)^2-(XP-ZP)^2]+(XP-ZP)^2
    mp2_add(t0, t1, Q->X);                          // XQ = (XP+ZP)*(XQ-ZQ)+(XP-ZP)*(XQ+ZQ)
    fp2mul_mont(P->Z, t2, P->Z);                    // ZP = [A24*[(XP+ZP)^2-(XP-ZP)^2]+(XP-ZP)^2]*[(XP+ZP)^2-(XP-ZP)^2]
    fp2sqr_mont(Q->Z, Q->Z);                        // ZQ = [(XP+ZP)*(XQ-ZQ)-(XP-ZP)*(XQ+ZQ)]^2
    fp2sqr_mont(Q->X, Q->X);                        // XQ = [(XP+ZP)*(XQ-ZQ)+(XP-ZP)*(XQ+ZQ)]^2
    fp2mul_mont(Q->Z, xPQ, Q->Z);                   // ZQ = xPQ*[(XP+ZP)*(XQ-ZQ)-(XP-ZP)*(XQ+ZQ)]^2
}


void xADD(point_proj_t Q, const point_proj_t P2, const f2elm_t xPQ)
{ // Differential addition with precomputed doubling point.
  // Input: projective Montgomery points P2=(XP:ZP) (precomputed) and Q=(XQ:ZQ) such that xP2=XP/ZP and xQ=XQ/ZQ, affine difference xPQ=x(P2-Q) and Montgomery curve constant A24=(A+2)/4.
  // Output: projective Montgomery point Q <- P2+Q = (XQP:ZQP) such that = x(Q+P2)=XQP/ZQP.
    f2elm_t t0, t1, t2;

    mp2_add(P2->X, P2->Z, t0);                      // t0 = XP+ZP
    mp2_sub_p2(P2->X, P2->Z, t1);                   // t1 = XP-ZP
    mp2_sub_p2(Q->X, Q->Z, t2);                     // t2 = XQ-ZQ
    mp2_add(Q->X, Q->Z, Q->X);                      // XQ = XQ+ZQ
    fp2mul_mont(t0, t2, t0);                        // t0 = (XP+ZP)*(XQ-ZQ)
    fp2mul_mont(t1, Q->X, t1);                      // t1 = (XP-ZP)*(XQ+ZQ)
    mp2_sub_p2(t0, t1, Q->Z);                       // ZQ = (XP+ZP)*(XQ-ZQ)-(XP-ZP)*(XQ+ZQ)
    mp2_add(t0, t1, Q->X);                          // XQ = (XP+ZP)*(XQ-ZQ)+(XP-ZP)*(XQ+ZQ)
    fp2sqr_mont(Q->Z, Q->Z);                        // ZQ = [(XP+ZP)*(XQ-ZQ)-(XP-ZP)*(XQ+ZQ)]^2
    fp2sqr_mont(Q->X, Q->X);                        // XQ = [(XP+ZP)*(XQ-ZQ)+(XP-ZP)*(XQ+ZQ)]^2
    fp2mul_mont(Q->Z, xPQ, Q->Z);                   // ZQ = xPQ*[(XP+ZP)*(XQ-ZQ)-(XP-ZP)*(XQ+ZQ)]^2
}


static void swap_points(point_proj_t P, point_proj_t Q, const digit_t option)
{ // Swap points.
  // If option = 0 then P <- P and Q <- Q, else if option = 0xFF...FF then P <- Q and Q <- P
    digit_t temp;
    unsigned int i;

    for (i = 0; i < NWORDS_FIELD; i++) {
        temp = option & (P->X[0][i] ^ Q->X[0][i]);
        P->X[0][i] = temp ^ P->X[0][i]; 
        Q->X[0][i] = temp ^ Q->X[0][i];  
        temp = option & (P->X[1][i] ^ Q->X[1][i]);
        P->X[1][i] = temp ^ P->X[1][i]; 
        Q->X[1][i] = temp ^ Q->X[1][i];
        temp = option & (P->Z[0][i] ^ Q->Z[0][i]);
        P->Z[0][i] = temp ^ P->Z[0][i]; 
        Q->Z[0][i] = temp ^ Q->Z[0][i];
        temp = option & (P->Z[1][i] ^ Q->Z[1][i]);
        P->Z[1][i] = temp ^ P->Z[1][i]; 
        Q->Z[1][i] = temp ^ Q->Z[1][i]; 
    }
}


static void LADDER3PT(const f2elm_t xP, const f2elm_t xQ, const f2elm_t xPQ, const unsigned char* m, const unsigned int AliceOrBob, point_proj_t R, const f2elm_t A)
{
    point_proj_t R0 = {0}, R2 = {0};
    f2elm_t A24 = {0};
    digit_t mask;
    int i, nbits, bit, swap, prevbit = 0;

    if (AliceOrBob == ALICE) {
        nbits = OALICE_BITS;
    } else {
        nbits = OBOB_BITS - 1;
    }

    // Initializing constant
    fpcopy((digit_t*)&Montgomery_one, A24[0]);
    mp2_add(A24, A24, A24);
    mp2_add(A, A24, A24);
    fp2div2(A24, A24);  
    fp2div2(A24, A24);  // A24 = (A+2)/4

    // Initializing points
    fp2copy(xQ, R0->X);
    fpcopy((digit_t*)&Montgomery_one, (digit_t*)R0->Z);
    fp2copy(xPQ, R2->X);
    fpcopy((digit_t*)&Montgomery_one, (digit_t*)R2->Z);
    fp2copy(xP, R->X);
    fpcopy((digit_t*)&Montgomery_one, (digit_t*)R->Z);
    fpzero((digit_t*)(R->Z)[1]);

    // Main loop
    for (i = 0; i < nbits; i++) {
        bit = (m[i >> 3] >> (i & 7)) & 1;
        swap = bit ^ prevbit;
        prevbit = bit;
        mask = 0 - (digit_t)swap;

        swap_points(R, R2, mask);
        xDBLADD(R0, R2, R->X, A24);
        fp2mul_mont(R2->X, R->Z, R2->X);
    }
    swap = 0 ^ prevbit;
    mask = 0 - (digit_t)swap;
    swap_points(R, R2, mask);
}

unsigned long dbleloop_count = 0;
unsigned long dbl_count = 0;
unsigned long get4iso_count = 0;
unsigned long eval4iso_count = 0;

void TraverseTree(f2elm_t jinv, point_proj_t R, f2elm_t A24plus, f2elm_t C24, const unsigned int *strat, unsigned int lenstrat, bool keygen,
                  point_proj_t phiP, point_proj_t phiQ, point_proj_t phiR) 
{ // Isogeny tree traversal
    point_proj_t pts[MAX_INT_POINTS_ALICE];
    f2elm_t coeff[3];
    unsigned int i, m, row, ii = 0, index = 0, npts = 0, pts_index[MAX_INT_POINTS_ALICE];

    for (row = 1; row < lenstrat; row++) {
        while (index < lenstrat - row) {
            fp2copy(R->X, pts[npts]->X);
            fp2copy(R->Z, pts[npts]->Z);
            pts_index[npts++] = index;
            m = strat[ii++];
            dbleloop_count++;                   // COUNTER
            dbl_count+=2*m;                     // COUNTER
            xDBLe(R, R, A24plus, C24, (int)(2*m));
            index += m;
        }
        get4iso_count++;                        // COUNTER

#ifdef GET_4_ISOG_AND_EVAL_4_ISOG_HARDWARE
            // start get_4_isog computation
            get_4_isog_and_eval_4_isog_hw((digit_t*)&((R->X)[0]), 
                                          (digit_t*)&((R->X)[1]), 
                                          (digit_t*)&((R->Z)[0]), 
                                          (digit_t*)&((R->Z)[1]), 
                                          NULL, 
                                          NULL, 
                                          NULL, 
                                          NULL, 
                                          (digit_t*)&(A24plus[0]), 
                                          (digit_t*)&(A24plus[1]),  
                                          (digit_t*)&(C24[0]), 
                                          (digit_t*)&(C24[1]), 
                                          1, 0, 0);
            // first eval_4_isog computation
           eval4iso_count++;
           get_4_isog_and_eval_4_isog_hw((digit_t*)&((pts[0]->X)[0]), 
                                         (digit_t*)&((pts[0]->X)[1]), 
                                         (digit_t*)&((pts[0]->Z)[0]), 
                                         (digit_t*)&((pts[0]->Z)[1]),    
                                         NULL,     
                                         NULL,     
                                         NULL,    
                                         NULL,   
                                         NULL, 
                                         NULL, 
                                         NULL, 
                                         NULL, 
                                         0, 1, 0); 

            if (keygen) {
                for (i = 1; i < npts; i++)  {
                    // middle eval_4_isog computations
                    eval4iso_count++;
                    get_4_isog_and_eval_4_isog_hw((digit_t*)&((pts[i]->X)[0]), 
                                                  (digit_t*)&((pts[i]->X)[1]), 
                                                  (digit_t*)&((pts[i]->Z)[0]), 
                                                  (digit_t*)&((pts[i]->Z)[1]),    
                                                  (digit_t*)&((pts[i-1]->X)[0]), 
                                                  (digit_t*)&((pts[i-1]->X)[1]), 
                                                  (digit_t*)&((pts[i-1]->Z)[0]), 
                                                  (digit_t*)&((pts[i-1]->Z)[1]),  
                                                  NULL, 
                                                  NULL, 
                                                  NULL, 
                                                  NULL, 
                                                  0, 0, 0); 
              }
              // keygen = 1
              get_4_isog_and_eval_4_isog_hw((digit_t*)&((phiP->X)[0]), 
                                            (digit_t*)&((phiP->X)[1]), 
                                            (digit_t*)&((phiP->Z)[0]), 
                                            (digit_t*)&((phiP->Z)[1]),    
                                            (digit_t*)&((pts[npts-1]->X)[0]), 
                                            (digit_t*)&((pts[npts-1]->X)[1]), 
                                            (digit_t*)&((pts[npts-1]->Z)[0]), 
                                            (digit_t*)&((pts[npts-1]->Z)[1]),  
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            0, 0, 0);  
              // keygen = 1
              get_4_isog_and_eval_4_isog_hw((digit_t*)&((phiQ->X)[0]), 
                                            (digit_t*)&((phiQ->X)[1]), 
                                            (digit_t*)&((phiQ->Z)[0]), 
                                            (digit_t*)&((phiQ->Z)[1]),    
                                            (digit_t*)&((phiP->X)[0]), 
                                            (digit_t*)&((phiP->X)[1]), 
                                            (digit_t*)&((phiP->Z)[0]), 
                                            (digit_t*)&((phiP->Z)[1]),  
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            0, 0, 0);
              // keygen = 1
              get_4_isog_and_eval_4_isog_hw((digit_t*)&((phiR->X)[0]), 
                                            (digit_t*)&((phiR->X)[1]), 
                                            (digit_t*)&((phiR->Z)[0]), 
                                            (digit_t*)&((phiR->Z)[1]),    
                                            (digit_t*)&((phiQ->X)[0]), 
                                            (digit_t*)&((phiQ->X)[1]), 
                                            (digit_t*)&((phiQ->Z)[0]), 
                                            (digit_t*)&((phiQ->Z)[1]), 
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            0, 0, 0);
              // last eval_4_isog computation
              get_4_isog_and_eval_4_isog_hw(NULL, 
                                            NULL, 
                                            NULL, 
                                            NULL,    
                                            (digit_t*)&((phiR->X)[0]), 
                                            (digit_t*)&((phiR->X)[1]), 
                                            (digit_t*)&((phiR->Z)[0]), 
                                            (digit_t*)&((phiR->Z)[1]), 
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            0, 0, 1);
          }
          else {
              for (i = 1; i < npts; i++)  {
                  // middle eval_4_isog computations
                  eval4iso_count++;
                  get_4_isog_and_eval_4_isog_hw((digit_t*)&((pts[i]->X)[0]), 
                                                (digit_t*)&((pts[i]->X)[1]), 
                                                (digit_t*)&((pts[i]->Z)[0]), 
                                                (digit_t*)&((pts[i]->Z)[1]),    
                                                (digit_t*)&((pts[i-1]->X)[0]), 
                                                (digit_t*)&((pts[i-1]->X)[1]), 
                                                (digit_t*)&((pts[i-1]->Z)[0]), 
                                                (digit_t*)&((pts[i-1]->Z)[1]),  
                                                NULL, 
                                                NULL, 
                                                NULL, 
                                                NULL, 
                                                0, 0, 0); 
              }
              // final eval_4_isog computation
              get_4_isog_and_eval_4_isog_hw(NULL, 
                                            NULL, 
                                            NULL, 
                                            NULL,    
                                            (digit_t*)&((pts[npts-1]->X)[0]), 
                                            (digit_t*)&((pts[npts-1]->X)[1]), 
                                            (digit_t*)&((pts[npts-1]->Z)[0]), 
                                            (digit_t*)&((pts[npts-1]->Z)[1]),  
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            NULL, 
                                            0, 0, 1);              
          }

#else
        get_4_isog(R, A24plus, C24, coeff);
        if (keygen) {
            eval_4_isog(phiP, coeff);
            eval_4_isog(phiQ, coeff);
            eval_4_isog(phiR, coeff);
        }

        for (i = 0; i < npts; i++) {
            eval4iso_count++;                   // COUNTER
            eval_4_isog(pts[i], coeff);
        }
#endif

        fp2copy(pts[npts-1]->X, R->X);
        fp2copy(pts[npts-1]->Z, R->Z);
        index = pts_index[npts-1];
        npts -= 1;
    }
    get4iso_count++;                            // COUNTER
#ifdef GET_4_ISOG_AND_EVAL_4_ISOG_HARDWARE 
    // start get_4_isog computation
    get_4_isog_and_eval_4_isog_hw((digit_t*)&((R->X)[0]), 
                                  (digit_t*)&((R->X)[1]), 
                                  (digit_t*)&((R->Z)[0]), 
                                  (digit_t*)&((R->Z)[1]), 
                                  NULL, 
                                  NULL, 
                                  NULL, 
                                  NULL, 
                                  (digit_t*)&(A24plus[0]), 
                                  (digit_t*)&(A24plus[1]),  
                                  (digit_t*)&(C24[0]), 
                                  (digit_t*)&(C24[1]), 
                                  1, 0, 0);
#else
    get_4_isog(R, A24plus, C24, coeff);
#endif
    if (keygen) {
#ifdef GET_4_ISOG_AND_EVAL_4_ISOG_HARDWARE
        // first eval_4_isog computation
        get_4_isog_and_eval_4_isog_hw((digit_t*)&((phiP->X)[0]), 
                                      (digit_t*)&((phiP->X)[1]), 
                                      (digit_t*)&((phiP->Z)[0]), 
                                      (digit_t*)&((phiP->Z)[1]),    
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      0, 1, 0);  
        // middle eval_4_isog computation
        get_4_isog_and_eval_4_isog_hw((digit_t*)&((phiQ->X)[0]), 
                                      (digit_t*)&((phiQ->X)[1]), 
                                      (digit_t*)&((phiQ->Z)[0]), 
                                      (digit_t*)&((phiQ->Z)[1]),    
                                      (digit_t*)&((phiP->X)[0]), 
                                      (digit_t*)&((phiP->X)[1]), 
                                      (digit_t*)&((phiP->Z)[0]), 
                                      (digit_t*)&((phiP->Z)[1]),  
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      0, 0, 0);
        // middle eval_4_isog computation
        get_4_isog_and_eval_4_isog_hw((digit_t*)&((phiR->X)[0]), 
                                      (digit_t*)&((phiR->X)[1]), 
                                      (digit_t*)&((phiR->Z)[0]), 
                                      (digit_t*)&((phiR->Z)[1]),    
                                      (digit_t*)&((phiQ->X)[0]), 
                                      (digit_t*)&((phiQ->X)[1]), 
                                      (digit_t*)&((phiQ->Z)[0]), 
                                      (digit_t*)&((phiQ->Z)[1]), 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      0, 0, 0);
        // last eval_4_isog computation
        get_4_isog_and_eval_4_isog_hw(NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL,    
                                      (digit_t*)&((phiR->X)[0]), 
                                      (digit_t*)&((phiR->X)[1]), 
                                      (digit_t*)&((phiR->Z)[0]), 
                                      (digit_t*)&((phiR->Z)[1]), 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      NULL, 
                                      0, 0, 1);
#else
        eval_4_isog(phiP, coeff);
        eval_4_isog(phiQ, coeff);
        eval_4_isog(phiR, coeff);
#endif
        inv_3_way(phiP->Z, phiQ->Z, phiR->Z);
        fp2mul_mont(phiP->X, phiP->Z, phiP->X);
        fp2mul_mont(phiQ->X, phiQ->Z, phiQ->X);
        fp2mul_mont(phiR->X, phiR->Z, phiR->X);
    } else {
        fp2add(A24plus, A24plus, A24plus);
        fp2sub(A24plus, C24, A24plus);
        fp2add(A24plus, A24plus, A24plus);
        j_inv(A24plus, C24, jinv);
    }
}