//*******************************************************************************************
// vOW4SIKE on HW: a HW/SW co-design implementation of the vOW algorithm on SIKE
// Copyright (c) Microsoft Corporation
//
// Website: https://github.com/microsoft/vOW4SIKE_on_HW
// Released under MIT license
//
// Based on the SIDH library (https://github.com/microsoft/PQCrypto-SIDH) and the vOW4SIKE
// library (https://github.com/microsoft/vOW4SIKE) 
//
// Abstract: field arithmetic in x64 assembly for P377 on Linux
//*******************************************************************************************  

.intel_syntax noprefix  

// Format function and variable names for Mac OS X
#if defined(__APPLE__)
    #define fmt(f)    _##f
#else
    #define fmt(f)    f
#endif

// Registers that are used for parameter passing:
#define reg_p1  rdi
#define reg_p2  rsi
#define reg_p3  rdx

// Define addition instructions
#ifdef _MULX_
#ifdef _ADX_

#define ADD     adcx
#define ADC     adcx

#else

#define ADD     add
#define ADC     adc

#endif    
#endif


.text
//***********************************************************************
//  Field addition
//  Operation: c [reg_p3] = a [reg_p1] + b [reg_p2]
//*********************************************************************** 
.global fmt(fpadd377_asm)
fmt(fpadd377_asm):
  push   r12
  push   r13
  push   r14
  push   r15
  
  xor    rax, rax
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    r12, [reg_p1+32]
  mov    r13, [reg_p1+40]
  add    r8, [reg_p2] 
  adc    r9, [reg_p2+8] 
  adc    r10, [reg_p2+16] 
  adc    r11, [reg_p2+24] 
  adc    r12, [reg_p2+32] 
  adc    r13, [reg_p2+40]

  mov    rcx, [rip+p377x2]
  sub    r8, rcx
  mov    rdi, [rip+p377x2+8]
  sbb    r9, rdi
  sbb    r10, rdi
  mov    rsi, [rip+p377x2+24]
  sbb    r11, rsi
  mov    r14, [rip+p377x2+32]
  sbb    r12, r14
  mov    r15, [rip+p377x2+40]
  sbb    r13, r15
  sbb    rax, 0
  
  and    rcx, rax
  and    rdi, rax
  and    rsi, rax
  and    r14, rax
  and    r15, rax
  
  add    r8, rcx  
  adc    r9, rdi  
  adc    r10, rdi 
  adc    r11, rsi 
  adc    r12, r14   
  adc    r13, r15
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], r12 
  mov    [reg_p3+40], r13
  
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret


//***********************************************************************
//  Field subtraction
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global fmt(fpsub377_asm)
fmt(fpsub377_asm):
  push   r12
  push   r13
  
  xor    rax, rax
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    r12, [reg_p1+32]
  mov    r13, [reg_p1+40]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40]
  sbb    rax, 0  

  mov    rcx, [rip+p377x2]
  mov    rdi, [rip+p377x2+8]
  mov    rsi, [rip+p377x2+24]
  and    rcx, rax
  and    rdi, rax
  and    rsi, rax    
  add    r8, rcx  
  adc    r9, rdi  
  adc    r10, rdi 
  adc    r11, rsi
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11
  setc   cl  

  mov    rdi, [rip+p377x2+32]
  mov    rsi, [rip+p377x2+40]
  and    rdi, rax
  and    rsi, rax 
  bt     rcx, 0  
  adc    r12, rdi   
  adc    r13, rsi
  mov    [reg_p3+32], r12 
  mov    [reg_p3+40], r13
  
  pop    r13
  pop    r12
  ret


///////////////////////////////////////////////////////////////// MACRO
.macro SUB377_PX  P0  
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    rax, [reg_p1+32]
  mov    rcx, [reg_p1+40]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    rax, [reg_p2+32] 
  sbb    rcx, [reg_p2+40]

  mov    rdi, [rip+\P0]
  mov    rsi, [rip+\P0+8]
  add    r8, rdi
  adc    r9, rsi  
  adc    r10, rsi 
  mov    rdi, [rip+\P0+24]
  mov    rsi, [rip+\P0+32]
  adc    r11, rdi  
  mov    rdi, [rip+\P0+40]  
  adc    rax, rsi  
  adc    rcx, rdi
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], rax 
  mov    [reg_p3+40], rcx
  .endm


//***********************************************************************
//  Multiprecision subtraction with correction with 2*p377
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 2*p377
//*********************************************************************** 
.global fmt(mp_sub377_p2_asm)
fmt(mp_sub377_p2_asm):

  SUB377_PX  p377x2
  ret


//***********************************************************************
//  Multiprecision subtraction with correction with 4*p377
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 4*p377
//*********************************************************************** 
.global fmt(mp_sub377_p4_asm)
fmt(mp_sub377_p4_asm):

  SUB377_PX  p377x4
  ret


#ifdef _MULX_
    
///////////////////////////////////////////////////////////////// MACRO
// Schoolbook integer multiplication
// Inputs:  memory pointers M0 and M1
// Outputs: memory pointer C and regs T1, T2, T0
// Temps:   regs T0:T6
/////////////////////////////////////////////////////////////////

#ifdef _ADX_
.macro MUL192_SCHOOL M0, M1, C, T0, T1, T2, T3, T4, T5, T6
    mov    rdx, \M0
    mulx   \T0, \T1, \M1     // T0:T1 = A0*B0
    mov    \C, \T1           // C0_final
    mulx   \T1, \T2, 8\M1    // T1:T2 = A0*B1
    xor    rax, rax   
    adox   \T0, \T2        
    mulx   \T2, \T3, 16\M1   // T2:T3 = A0*B2
    adox   \T1, \T3
           
    mov    rdx, 8\M0
    mulx   \T3, \T4, \M1     // T3:T4 = A1*B0
    adox   \T2, rax 
    xor    rax, rax   
    mulx   \T5, \T6, 8\M1    // T5:T6 = A1*B1
    adox   \T4, \T0
    mov    8\C, \T4          // C1_final  
    adcx   \T3, \T6      
    mulx   \T6, \T0, 16\M1   // T6:T0 = A1*B2 
    adox   \T3, \T1  
    adcx   \T5, \T0     
    adcx   \T6, rax 
    adox   \T5, \T2	
    
    mov    rdx, 16\M0
    mulx   \T1, \T0, \M1     // T1:T0 = A2*B0
    adox   \T6, rax
    xor    rax, rax 
    mulx   \T2, \T4, 8\M1    // T2:T4 = A2*B1
    adox   \T0, \T3   
    mov    16\C, \T0         // C2_final 
    adcx   \T1, \T5    
    mulx   \T0, \T3, 16\M1   // T0:T3 = A2*B2
    adcx   \T2, \T6  
    adcx   \T0, rax
    adox   \T1, \T4
    adox   \T2, \T3
    adox   \T0, rax
.endm

#else

.macro MUL192_SCHOOL M0, M1, C, T0, T1, T2, T3, T4, T5, T6
    mov    rdx, \M0
    mulx   \T0, \T1, \M1     // T0:T1 = A0*B0
    mov    \C, \T1           // C0_final
    mulx   \T1, \T2, 8\M1    // T1:T2 = A0*B1
    add    \T0, \T2        
    mulx   \T2, \T3, 16\M1   // T2:T3 = A0*B2
    adc    \T1, \T3
           
    mov    rdx, 8\M0
    mulx   \T3, \T4, \M1     // T3:T4 = A1*B0
    adc    \T2, 0   
    mulx   \T5, \T6, 8\M1    // T5:T6 = A1*B1
    add    \T4, \T0
    mov    8\C, \T4          // C1_final
    adc    \T3, \T1  
    adc    \T5, \T2	    
    mulx   \T2, \T1, 16\M1   // T2:T1 = A1*B2
    adc    \T2, 0    

    add    \T3, \T6  
    adc    \T5, \T1     
    adc    \T2, 0
    
    mov    rdx, 16\M0
    mulx   \T1, \T0, \M1     // T1:T0 = A2*B0
    add    \T0, \T3   
    mov    16\C, \T0         // C2_final 
    mulx   \T4, \T6, 8\M1    // T4:T6 = A2*B1
    adc    \T1, \T5    
    adc    \T2, \T4 
    mulx   \T0, \T3, 16\M1   // T0:T3 = A2*B2 
    adc    \T0, 0
    add    \T1, \T6
    adc    \T2, \T3
    adc    \T0, 0
.endm
#endif


//*****************************************************************************
//  377-bit multiplication using Karatsuba (one level), schoolbook (one level)
//***************************************************************************** 
.global fmt(mul377_asm)
fmt(mul377_asm):    
    push   r14 
    push   r15
    mov    rcx, reg_p3 

    // r8-r10 <- AH + AL, rax <- mask
    xor    rax, rax
    mov    r8, [reg_p1]
    mov    r9, [reg_p1+8]
    mov    r10, [reg_p1+16]
    push   rbx 
    push   rbp
    add    r8, [reg_p1+24]
    adc    r9, [reg_p1+32]
    adc    r10, [reg_p1+40]
    sbb    rax, 0
    push   r12
    push   r13 

    // r11-r13 <- BH + BL, rbx <- mask
    xor    rbx, rbx
    mov    r11, [reg_p2]
    mov    r12, [reg_p2+8]
    mov    r13, [reg_p2+16]
    sub    rsp, 48
    add    r11, [reg_p2+24]
    adc    r12, [reg_p2+32]
    adc    r13, [reg_p2+40]
    sbb    rbx, 0
    mov    [rsp], r8
    mov    [rsp+8], r9
    mov    [rsp+16], r10
    mov    [rsp+24], r11
    mov    [rsp+32], r12
    mov    [rsp+40], r13
    
    // r11-r13 <- masked (BH + BL)
    and    r11, rax
    and    r12, rax
    and    r13, rax

    // r8-r10 <- masked (AH + AL)
    and    r8, rbx
    and    r9, rbx
    and    r10, rbx

    // r8-r10 <- masked (AH + AL) + masked (AH + AL)
    add    r8, r11
    adc    r9, r12
    adc    r10, r13

    // [rcx+48] <- (AH+AL) x (BH+BL), low part 
    MUL192_SCHOOL  [rsp], [rsp+24], [rcx+48], r15, rbx, rbp, r11, r12, r13, r14 
    mov    [rcx+72], rbx         
    mov    [rcx+80], rbp         
    mov    [rcx+88], r15         

    // [rcx] <- AL x BL
    MUL192_SCHOOL  [reg_p1], [reg_p2], [rcx], r15, rbx, rbp, r11, r12, r13, r14     // Result C0-C2 
    mov    [rcx+24], rbx         
    mov    [rcx+32], rbp         
    mov    [rcx+40], r15         

    // [rsp], rbx, rbp, r15 <- AH x BH 
    MUL192_SCHOOL  [reg_p1+24], [reg_p2+24], [rsp], r15, rbx, rbp, r11, r12, r13, r14
    
    // r8-r10 <- (AH+AL) x (BH+BL), final step
    add    r8, [rcx+72]
    adc    r9, [rcx+80]
    adc    r10, [rcx+88]
    
    // r11-r13, r8-r10 <- (AH+AL) x (BH+BL) - ALxBL
    mov    r11, [rcx+48]
    mov    r12, [rcx+56]
    mov    r13, [rcx+64]
    sub    r11, [rcx]
    sbb    r12, [rcx+8]
    sbb    r13, [rcx+16]
    sbb    r8, [rcx+24]
    sbb    r9, [rcx+32]
    sbb    r10, [rcx+40]
    
    // r11-r13, r8-r10 <- (AH+AL) x (BH+BL) - ALxBL - AHxBH
    mov    rdi, [rsp]
    mov    rsi, [rsp+8]
    mov    rdx, [rsp+16]
    add    rsp, 48  
    sub    r11, rdi
    sbb    r12, rsi
    sbb    r13, rdx
    sbb    r8, rbx
    sbb    r9, rbp
    sbb    r10, r15
    
    add    r11, [rcx+24]
    adc    r12, [rcx+32]
    adc    r13, [rcx+40]
    mov    [rcx+24], r11    // Result C3-C5
    mov    [rcx+32], r12
    mov    [rcx+40], r13
    pop    r13
    pop    r12
    adc    r8, rdi 
    adc    r9, rsi
    adc    r10, rdx
    mov    [rcx+48], r8    // Result C6-C8
    mov    [rcx+56], r9 
    mov    [rcx+64], r10
    adc    rbx, 0
    adc    rbp, 0
    adc    r15, 0
    mov    [rcx+72], rbx   // Result C9-C11
    mov    [rcx+80], rbp 
    mov    [rcx+88], r15    
    
    pop    rbp  
    pop    rbx  
    pop    r15 
    pop    r14
    ret

#else

# error "CONFIGURATION NOT SUPPORTED. TRY USE_MULX=TRUE"

#endif


#ifdef _MULX_

///////////////////////////////////////////////////////////////// MACRO
// Schoolbook integer multiplication
// Inputs:  regs I0, I1 and memory pointer M1
// Outputs: regs T0:T4
// Temp:    regs T0:T5
/////////////////////////////////////////////////////////////////

.macro MUL128x192_SCHOOL I0, I1, M1, T0, T1, T2, T3, T4, T5
    xor    rax, rax
    mulx   \T3, \T5, 16\M1 
    ADD    \T1, \T4               
    ADC    \T2, \T5 
    ADC    \T3, rax   
    
    xor    rax, rax
    mov    rdx, \I1 
    mulx   \T4, \T5, \M1 
    ADD    \T1, \T5            // T1 <- C1_final 
    ADC    \T2, \T4     
    mulx   \T4, \T5, 8\M1
    ADC    \T3, rax
    ADD    \T2, \T5            // T2 <- C2_final  
    ADC    \T3, \T4       
    mulx   \T4, \T5, 16\M1  
    ADC    \T4, rax       
    ADD    \T3, \T5            // T3 <- C3_final  
    ADC    \T4, rax            // T4 <- C4_final 
.endm

  
//**************************************************************************************
//  Montgomery reduction, shifted
//  Based on method described in Faz-Hernandez et al. https://eprint.iacr.org/2017/1015  
//  Operation: c [reg_p2] = a [reg_p1]
//************************************************************************************** 
.global fmt(rdc377_asm)
fmt(rdc377_asm):

    // a[0-1] x 2xp377p1_nz --> result: r8:r12
    mov    rdx, [reg_p1]
    mov    rcx, [reg_p1+8]
    mulx   r9, r8, [rip+p377p1x2]   // result r8 
    push   r15
    push   rbp
    push   r14 
    push   r12
    mulx   r10, r12, [rip+p377p1x2+8] 
    push   rbx 
    push   r13
    MUL128x192_SCHOOL rdx, rcx, [rip+p377p1x2], r8, r9, r10, r11, r12, r13     
        
    xor    rdx, rdx
    shrd   rdx, r8, 1 
    shrd   r8, r9, 1 
    shrd   r9, r10, 1 
    shrd   r10, r11, 1 
    shrd   r11, r12, 1 
    shr    r12, 1
    add    rdx, [reg_p1+16]
    adc    r8, [reg_p1+24]  
    adc    r9, [reg_p1+32] 
    adc    r10, [reg_p1+40]      
    mulx   rbx, rcx, [rip+p377p1x2]   // result rcx 
    adc    r11, [reg_p1+48] 
    adc    r12, [reg_p1+56]  
    mov    [reg_p2], r9  
    mov    [reg_p2+8], r10  
    mov    [reg_p2+16], r11
    mov    r9, [reg_p1+64]  
    mov    r10, [reg_p1+72]
    mov    r11, [reg_p1+80]   
    mov    rdi, [reg_p1+88]
    mulx   rbp, r15, [rip+p377p1x2+8] 
    adc    r9, 0
    adc    r10, 0
    adc    r11, 0
    adc    rdi, 0 

    // a[2-3] x 2xp377p1_nz --> result: rcx, rbx, rbp, r14:r15
    MUL128x192_SCHOOL rdx, r8, [rip+p377p1x2], rcx, rbx, rbp, r14, r15, r13

    xor    rdx, rdx
    shrd   rdx, rcx, 1 
    shrd   rcx, rbx, 1 
    shrd   rbx, rbp, 1 
    shrd   rbp, r14, 1 
    shrd   r14, r15, 1 
    shr    r15, 1
    add    rdx, [reg_p2] 
    adc    rcx, [reg_p2+8]  
    adc    rbx, [reg_p2+16] 
    mov    [reg_p2+16], rbx  
    adc    r12, rbp
    mulx   rbp, rbx, [rip+p377p1x2]   // result rbx   
    adc    r14, r9  
    adc    r15, r10  
    mulx   r10, r8, [rip+p377p1x2+8] 
    adc    r11, 0
    adc    rdi, 0

    // a[4-5] x 2xp377p1_nz --> result: rbx, rbp, r10:r8
    MUL128x192_SCHOOL rdx, rcx, [rip+p377p1x2], rbx, rbp, r10, r9, r8, r13  

    xor    rdx, rdx
    pop    r13
    shrd   rdx, rbx, 1 
    shrd   rbx, rbp, 1 
    shrd   rbp, r10, 1 
    shrd   r10, r9, 1 
    shrd   r9, r8, 1 
    shr    r8, 1
    add    rdx, [reg_p2+16]
    adc    rbx, r12 
    mov    [reg_p2+8], rbx  
    pop    rbx  
    pop    r12          
    adc    rbp, r14    
    pop    r14  
    mov    [reg_p2+16], rbp 
    pop    rbp               
    adc    r10, r15   
    pop    r15      
    mov    [reg_p2+24], r10          
    adc    r9, r11  
    adc    r8, rdi
    mov    [reg_p2], rdx       // Final result c0-c5 
    mov    [reg_p2+32], r9  
    mov    [reg_p2+40], r8
    ret

  #else

  # error "CONFIGURATION NOT SUPPORTED. TRY USE_MULX=TRUE"

  #endif


//***********************************************************************
//  377-bit multiprecision addition
//  Operation: c [reg_p3] = a [reg_p1] + b [reg_p2]
//*********************************************************************** 
.global fmt(mp_add377_asm)
fmt(mp_add377_asm): 
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  add    r8, [reg_p2] 
  adc    r9, [reg_p2+8] 
  adc    r10, [reg_p2+16] 
  adc    r11, [reg_p2+24] 
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  
  mov    r8, [reg_p1+32]
  mov    r9, [reg_p1+40]
  adc    r8, [reg_p2+32] 
  adc    r9, [reg_p2+40] 
  mov    [reg_p3+32], r8
  mov    [reg_p3+40], r9
  ret


//***************************************************************************
//  2x377-bit multiprecision subtraction/addition
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + p377*p377*2^16
//*************************************************************************** 
.global fmt(mp_subadd377x2_asm)
fmt(mp_subadd377x2_asm):
  push   r12
  push   r13
  
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    r12, [reg_p1+32]
  mov    r13, [reg_p1+40]
  mov    rcx, [rip+p377x16p] 
  add    r8, rcx 
  adc    r9, 0 
  adc    r10, 0 
  mov    rcx, [rip+p377x16p+24] 
  adc    r11, rcx 
  mov    rcx, [rip+p377x16p+32] 
  adc    r12, rcx 
  mov    rcx, [rip+p377x16p+40] 
  adc    r13, rcx 
  setc   al  
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40] 
  setc   cl  
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], r12
  mov    [reg_p3+40], r13
   
  mov    r8, [reg_p1+48]
  mov    r9, [reg_p1+56] 
  mov    r10, [reg_p1+64]
  mov    r11, [reg_p1+72] 
  mov    r12, [reg_p1+80]
  mov    r13, [reg_p1+88]
  bt     rax, 0  
  adc    r8, [rip+p377x16p+48] 
  adc    r9, [rip+p377x16p+56]
  adc    r10, [rip+p377x16p+64] 
  adc    r11, [rip+p377x16p+72]  
  adc    r12, [rip+p377x16p+80]
  adc    r13, [rip+p377x16p+88]  
  bt     rcx, 0  
  sbb    r8, [reg_p2+48] 
  sbb    r9, [reg_p2+56]
  sbb    r10, [reg_p2+64] 
  sbb    r11, [reg_p2+72]  
  sbb    r12, [reg_p2+80]
  sbb    r13, [reg_p2+88]
  
  mov    [reg_p3+48], r8
  mov    [reg_p3+56], r9
  mov    [reg_p3+64], r10
  mov    [reg_p3+72], r11
  mov    [reg_p3+80], r12
  mov    [reg_p3+88], r13
  
  pop    r13
  pop    r12
  ret


//***********************************************************************
//  Double 2x377-bit multiprecision subtraction
//  Operation: c [reg_p3] = c [reg_p3] - a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global fmt(mp_dblsub377x2_asm)
fmt(mp_dblsub377x2_asm):
  push   r12
  push   r13
  
  mov    r8, [reg_p3]
  mov    r9, [reg_p3+8]
  mov    r10, [reg_p3+16]
  mov    r11, [reg_p3+24]
  mov    r12, [reg_p3+32]
  mov    r13, [reg_p3+40]
  sub    r8, [reg_p1]
  sbb    r9, [reg_p1+8] 
  sbb    r10, [reg_p1+16] 
  sbb    r11, [reg_p1+24] 
  sbb    r12, [reg_p1+32] 
  sbb    r13, [reg_p1+40] 
  setc   al  
  sub    r8, [reg_p2]
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40]
  setc   cl  
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], r12
  mov    [reg_p3+40], r13
    
  mov    r8, [reg_p3+48]
  mov    r9, [reg_p3+56]
  mov    r10, [reg_p3+64]
  mov    r11, [reg_p3+72]
  mov    r12, [reg_p3+80]
  mov    r13, [reg_p3+88]
  bt     rax, 0  
  sbb    r8, [reg_p1+48] 
  sbb    r9, [reg_p1+56] 
  sbb    r10, [reg_p1+64] 
  sbb    r11, [reg_p1+72] 
  sbb    r12, [reg_p1+80] 
  sbb    r13, [reg_p1+88]
  bt     rcx, 0  
  sbb    r8, [reg_p2+48] 
  sbb    r9, [reg_p2+56] 
  sbb    r10, [reg_p2+64] 
  sbb    r11, [reg_p2+72] 
  sbb    r12, [reg_p2+80] 
  sbb    r13, [reg_p2+88] 
  mov    [reg_p3+48], r8
  mov    [reg_p3+56], r9
  mov    [reg_p3+64], r10
  mov    [reg_p3+72], r11
  mov    [reg_p3+80], r12
  mov    [reg_p3+88], r13
  
  pop    r13
  pop    r12
  ret