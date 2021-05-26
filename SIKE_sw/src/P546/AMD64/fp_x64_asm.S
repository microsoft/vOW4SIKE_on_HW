//*******************************************************************************************
// SIDH: an efficient supersingular isogeny cryptography library 
// Copyright (c) Microsoft Corporation
//
// Website: https://github.com/microsoft/PQCrypto-SIDH
// Released under MIT license 
//
// Abstract: field arithmetic in x64 assembly for P546 on Linux 
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


.text
//***********************************************************************
//  Field addition
//  Operation: c [reg_p3] = a [reg_p1] + b [reg_p2]
//*********************************************************************** 
.global fmt(fpadd546_asm)
fmt(fpadd546_asm):
  push   r12
  push   r13
  push   r14
  push   r15
  
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    r12, [reg_p1+32]
  mov    r13, [reg_p1+40]
  mov    r14, [reg_p1+48]
  mov    r15, [reg_p1+56] 
  mov    rcx, [reg_p1+64]
  add    r8, [reg_p2] 
  adc    r9, [reg_p2+8] 
  adc    r10, [reg_p2+16] 
  adc    r11, [reg_p2+24] 
  adc    r12, [reg_p2+32] 
  adc    r13, [reg_p2+40] 
  adc    r14, [reg_p2+48] 
  adc    r15, [reg_p2+56]
  adc    rcx, [reg_p2+64]

  mov    rax, [rip+fmt(p546x2)]
  sub    r8, rax
  mov    rax, [rip+fmt(p546x2)+8]
  sbb    r9, rax
  sbb    r10, rax
  sbb    r11, rax
  mov    rax, [rip+fmt(p546x2)+32]
  sbb    r12, rax
  mov    rax, [rip+fmt(p546x2)+40]
  sbb    r13, rax
  mov    rax, [rip+fmt(p546x2)+48]
  sbb    r14, rax
  mov    rax, [rip+fmt(p546x2)+56]
  sbb    r15, rax
  mov    rax, [rip+fmt(p546x2)+64]
  sbb    rcx, rax
  mov    [reg_p3+64], rcx
  mov    rax, 0
  sbb    rax, 0
  
  mov    rsi, [rip+fmt(p546x2)]
  and    rsi, rax
  mov    rdi, [rip+fmt(p546x2)+8]
  and    rdi, rax
  
  add    r8, rsi  
  adc    r9, rdi 
  adc    r10, rdi
  adc    r11, rdi
  mov    [reg_p3], r8 
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11 
  setc   cl
  
  mov    rdi, [rip+fmt(p546x2)+32]
  and    rdi, rax
  mov    rsi, [rip+fmt(p546x2)+40]
  and    rsi, rax
  mov    r8, [rip+fmt(p546x2)+48]
  and    r8, rax
  mov    r9, [rip+fmt(p546x2)+56]
  and    r9, rax
  mov    r10, [rip+fmt(p546x2)+64]
  and    r10, rax
  
  bt     rcx, 0
  adc    r12, rdi
  adc    r13, rsi  
  adc    r14, r8
  adc    r15, r9
  mov    rsi, [reg_p3+64]
  adc    rsi, r10
  mov    [reg_p3+32], r12  
  mov    [reg_p3+40], r13
  mov    [reg_p3+48], r14
  mov    [reg_p3+56], r15  
  mov    [reg_p3+64], rsi

  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret


//***********************************************************************
//  Field subtraction
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global fmt(fpsub546_asm)
fmt(fpsub546_asm):
  push   r12
  push   r13
  push   r14
  push   r15
  
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    r12, [reg_p1+32]
  mov    r13, [reg_p1+40]
  mov    r14, [reg_p1+48]
  mov    r15, [reg_p1+56] 
  mov    rcx, [reg_p1+64]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40] 
  sbb    r14, [reg_p2+48] 
  sbb    r15, [reg_p2+56]
  sbb    rcx, [reg_p2+64]
  mov    [reg_p3+64], rcx
  mov    rax, 0
  sbb    rax, 0
    
  mov    rsi, [rip+fmt(p546x2)]
  and    rsi, rax
  mov    rdi, [rip+fmt(p546x2)+8]
  and    rdi, rax
  
  add    r8, rsi  
  adc    r9, rdi 
  adc    r10, rdi 
  adc    r11, rdi
  mov    [reg_p3], r8 
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11 
  setc   cl
  
  mov    rdi, [rip+fmt(p546x2)+32]
  and    rdi, rax
  mov    rsi, [rip+fmt(p546x2)+40]
  and    rsi, rax
  mov    r8, [rip+fmt(p546x2)+48]
  and    r8, rax
  mov    r9, [rip+fmt(p546x2)+56]
  and    r9, rax
  mov    r10, [rip+fmt(p546x2)+64]
  and    r10, rax
  
  bt     rcx, 0
  adc    r12, rdi
  adc    r13, rsi  
  adc    r14, r8
  adc    r15, r9
  mov    rsi, [reg_p3+64]
  adc    rsi, r10
  mov    [reg_p3+32], r12  
  mov    [reg_p3+40], r13
  mov    [reg_p3+48], r14
  mov    [reg_p3+56], r15  
  mov    [reg_p3+64], rsi
  
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret 


///////////////////////////////////////////////////////////////// MACRO
.macro SUB546_PX  P0
  push   r12
  push   r13
  push   r14
  push   r15
  
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    r12, [reg_p1+32]
  mov    r13, [reg_p1+40]
  mov    r14, [reg_p1+48]
  mov    r15, [reg_p1+56]
  mov    rax, [reg_p1+64]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40]
  sbb    r14, [reg_p2+48] 
  sbb    r15, [reg_p2+56] 
  sbb    rax, [reg_p2+64]

  mov    rdi, [rip+\P0]
  mov    rsi, [rip+\P0+8]
  add    r8, rdi  
  adc    r9, rsi  
  adc    r10, rsi 
  adc    r11, rsi 
  mov    rcx, [rip+\P0+32]
  mov    rdi, [rip+\P0+40]
  mov    rsi, [rip+\P0+48]
  adc    r12, rcx   
  adc    r13, rdi     
  adc    r14, rsi 
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], r12 
  mov    [reg_p3+40], r13
  mov    [reg_p3+48], r14
  mov    rdi, [rip+\P0+56]
  mov    rsi, [rip+\P0+64]
  adc    r15, rdi  
  adc    rax, rsi 
  mov    [reg_p3+56], r15 
  mov    [reg_p3+64], rax
  
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  .endm


//***********************************************************************
//  Multiprecision subtraction with correction with 2*p546
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 2*p546
//*********************************************************************** 
.global fmt(mp_sub546_p2_asm)
fmt(mp_sub546_p2_asm):

  SUB546_PX  fmt(p546x2)
  ret


//***********************************************************************
//  Multiprecision subtraction with correction with 4*p546
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 4*p546
//*********************************************************************** 
.global fmt(mp_sub546_p4_asm)
fmt(mp_sub546_p4_asm):

  SUB546_PX  fmt(p546x4)
  ret


#ifdef _MULX_

/////////////////////////////////////////////////////////////////////////// MACRO
// Schoolbook integer multiplication
// Inputs:  memory pointers M0 and M1
// Outputs: memory pointer C
// Temps:   regs T0:T7
///////////////////////////////////////////////////////////////////////////

#ifdef _ADX_
.macro MUL320_SCHOOL M0, M1, C, T0, T1, T2, T3, T4, T5, T6, T7 
    mov    rdx, \M0
    mulx   \T0, \T1, \M1    
    mulx   \T2, \T3, 8\M1
    mov    \C, \T1             // C0_final 
    xor    rax, rax
    mulx   \T4, \T5, 16\M1 
    adox   \T0, \T3               
    adox   \T2, \T5     
    mulx   \T1, \T3, 24\M1
    adox   \T4, \T3         
    mulx   \T5, \T6, 32\M1 
    adox   \T1, \T6     
    adox   \T5, rax        
    
    mov    rdx, 8\M0 
    mulx   \T6, \T7, \M1 
    xor    rax, rax
    adcx   \T0, \T7 
    mov    8\C, \T0            // C1_final 
    adcx   \T2, \T6     
    mulx   \T6, \T7, 8\M1
    adox   \T2, \T7 
    adcx   \T4, \T6        
    mulx   \T0, \T6, 16\M1 
    adox   \T4, \T6  
    adcx   \T0, \T1     
    mulx   \T1, \T7, 24\M1   
    adcx   \T1, \T5 
    adox   \T0, \T7   
    mulx   \T5, \T6, 32\M1 
    adcx   \T5, rax         
    adox   \T1, \T6  
    adox   \T5, rax         
    
    mov    rdx, 16\M0 
    mulx   \T6, \T7, \M1
    xor    rax, rax 
    adcx   \T2, \T7 
    mov    16\C, \T2           // C2_final 
    adcx   \T4, \T6     
    mulx   \T6, \T7, 8\M1
    adox   \T4, \T7 
    adcx   \T0, \T6        
    mulx   \T2, \T6, 16\M1
    adox   \T0, \T6 
    adcx   \T1, \T2     
    mulx   \T2, \T7, 24\M1   
    adcx   \T5, \T2          
    adox   \T1, \T7   
    mulx   \T2, \T6, 32\M1   
    adcx   \T2, rax 
    adox   \T5, \T6 
    adox   \T2, rax           
    
    mov    rdx, 24\M0 
    mulx   \T6, \T7, \M1
    xor    rax, rax 
    adcx   \T4, \T7 
    mov    24\C, \T4           // C3_final 
    adcx   \T0, \T6     
    mulx   \T6, \T7, 8\M1
    adox   \T0, \T7
    adcx   \T1, \T6        
    mulx   \T4, \T6, 16\M1
    adox   \T1, \T6  
    adcx   \T5, \T4     
    mulx   \T4, \T7, 24\M1   
    adcx   \T2, \T4        
    adox   \T5, \T7   
    mulx   \T4, \T6, 32\M1   
    adcx   \T4, rax 
    adox   \T2, \T6  
    adox   \T4, rax         
    
    mov    rdx, 32\M0 
    mulx   \T6, \T7, \M1 
    xor    rax, rax
    adcx   \T0, \T7 
    mov    32\C, \T0           // C4_final 
    adcx   \T1, \T6     
    mulx   \T6, \T7, 8\M1
    adox   \T1, \T7 
    adcx   \T5, \T6        
    mulx   \T0, \T6, 16\M1 
    adox   \T5, \T6 
    adcx   \T2, \T0     
    mulx   \T0, \T7, 24\M1   
    adcx   \T4, \T0 
    adox   \T2, \T7  
    mulx   \T0, \T6, 32\M1   
    adcx   \T0, rax           
    adox   \T4, \T6 
    adox   \T0, rax 

    mov    40\C, \T1 
    mov    48\C, \T5 
    mov    56\C, \T2 
    mov    64\C, \T4
    mov    72\C, \T0
.endm

.macro MUL256_SCHOOL M0, M1, C, T0, T1, T2, T3, T4, T5, T6, T7, T8, T9
    mov    rdx, \M0
    mulx   \T0, \T1, \M1     // T0:T1 = A0*B0
    mov    \C, \T1           // C0_final
    mulx   \T1, \T2, 8\M1    // T1:T2 = A0*B1
    xor    rax, rax   
    adox   \T0, \T2        
    mulx   \T2, \T3, 16\M1   // T2:T3 = A0*B2
    adox   \T1, \T3        
    mulx   \T3, \T4, 24\M1   // T3:T4 = A0*B3
    adox   \T2, \T4 
           
    mov    rdx, 8\M0
    mulx   \T5, \T4, \M1     // T5:T4 = A1*B0
    adox   \T3, rax 
    xor    rax, rax   
    mulx   \T6, \T7, 8\M1    // T6:T7 = A1*B1
    adox   \T4, \T0
    mov    8\C, \T4          // C1_final  
    adcx   \T5, \T7      
    mulx   \T7, \T8, 16\M1   // T7:T8 = A1*B2
    adcx   \T6, \T8  
    adox   \T5, \T1      
    mulx   \T8, \T9, 24\M1   // T8:T9 = A1*B3
    adcx   \T7, \T9        
    adcx   \T8, rax   
    adox   \T6, \T2
    
    mov    rdx, 16\M0
    mulx   \T1, \T0, \M1     // T1:T0 = A2*B0
    adox   \T7, \T3
    adox   \T8, rax
    xor    rax, rax 
    mulx   \T2, \T3, 8\M1    // T2:T3 = A2*B1
    adox   \T0, \T5   
    mov    16\C, \T0         // C2_final 
    adcx   \T1, \T3    
    mulx   \T3, \T4, 16\M1   // T3:T4 = A2*B2
    adcx   \T2, \T4 
    adox   \T1, \T6       
    mulx   \T4,\T9, 24\M1    // T3:T4 = A2*B3
    adcx   \T3, \T9        
    mov    rdx, 24\M0
    adcx   \T4, rax         

    adox   \T2, \T7
    adox   \T3, \T8
    adox   \T4, rax

    mulx   \T5, \T0, \M1     // T5:T0 = A3*B0
    xor    rax, rax 
    mulx   \T6, \T7, 8\M1    // T6:T7 = A3*B1
    adcx   \T5, \T7 
    adox   \T1, \T0       
    mulx   \T7, \T8, 16\M1   // T7:T8 = A3*B2
    adcx   \T6, \T8  
    adox   \T2, \T5      
    mulx   \T8, \T9, 24\M1   // T8:T9 = A3*B3
    adcx   \T7, \T9        
    adcx   \T8, rax         

    adox   \T3, \T6
    adox   \T4, \T7
    adox   \T8, rax
    mov    24\C, \T1         // C3_final
    mov    32\C, \T2         // C4_final
    mov    40\C, \T3         // C5_final
    mov    48\C, \T4         // C6_final
    mov    56\C, \T8         // C7_final
.endm

#else

.macro MUL320_SCHOOL M0, M1, C, T0, T1, T2, T3, T4, T5, T6, T7
    mov    rdx, \M0
    mulx   \T0, \T1, \M1    
    mulx   \T2, \T3, 8\M1
    mov    \C, \T1             // C0_final 
    mulx   \T4, \T5, 16\M1 
    add    \T0, \T3               
    adc    \T2, \T5     
    mulx   \T1, \T3, 24\M1
    adc    \T3, \T4         
    mulx   \T5, \T6, 32\M1 
    adc    \T1, \T6     
    adc    \T5, 0        
    
    mov    rdx, 8\M0 
    mulx   \T6, \T7, \M1 
    add    \T0, \T7 
    mov    8\C, \T0            // C1_final 
    adc    \T2, \T6     
    mulx   \T6, \T7, 8\M1
    adc    \T3, \T6        
    mulx   \T0, \T4, 16\M1
    adc    \T0, \T1     
    mulx   \T1, \T6, 24\M1   
    adc    \T5, \T1  
    mulx   \T1, rax, 32\M1     
    adc    \T1, 0 
        
    add    \T2, \T7 
    adc    \T3, \T4  
    adc    \T0, \T6  
    adc    \T5, rax  
    adc    \T1, 0         
    
    mov    rdx, 16\M0 
    mulx   \T4, \T6, \M1 
    add    \T2, \T6 
    mov    16\C, \T2           // C2_final 
    adc    \T3, \T4     
    mulx   \T6, \T7, 8\M1
    adc    \T0, \T6        
    mulx   \T2, \T4, 16\M1 
    adc    \T2, \T5     
    mulx   \T5, \T6, 24\M1   
    adc    \T1, \T5 
    mulx   \T5, rax, 32\M1     
    adc    \T5, 0 
        
    add    \T3, \T7
    adc    \T0, \T4  
    adc    \T2, \T6  
    adc    \T1, rax 
    adc    \T5, 0          
    
    mov    rdx, 24\M0
    mulx   \T4, \T6, \M1 
    add    \T3, \T6 
    mov    24\C, \T3           // C3_final 
    adc    \T0, \T4     
    mulx   \T6, \T7, 8\M1
    adc    \T2, \T6        
    mulx   \T3, \T4, 16\M1 
    adc    \T1, \T3     
    mulx   \T3, \T6, 24\M1   
    adc    \T3, \T5 
    mulx   \T5, rax, 32\M1     
    adc    \T5, 0
        
    add    \T0, \T7
    adc    \T2, \T4  
    adc    \T1, \T6  
    adc    \T3, rax 
    adc    \T5, 0       
    
    mov    rdx, 32\M0 
    mulx   \T4, \T6, \M1 
    add    \T0, \T6 
    mov    32\C, \T0           // C4_final 
    adc    \T2, \T4     
    mulx   \T6, \T7, 8\M1
    adc    \T1, \T6        
    mulx   \T0, \T4, 16\M1 
    adc    \T3, \T0     
    mulx   \T0, \T6, 24\M1   
    adc    \T0, \T5 
    mulx   \T5, rax, 32\M1     
    adc    \T5, 0
        
    add    \T2, \T7 
    adc    \T1, \T4  
    adc    \T3, \T6 
    adc    \T0, rax 
    adc    \T5, 0 
    mov    40\C, \T2 
    mov    48\C, \T1 
    mov    56\C, \T3 
    mov    64\C, \T0
    mov    72\C, \T5 
.endm 

.macro MUL256_SCHOOL M0, M1, C, T0, T1, T2, T3, T4, T5, T6, T7, T8, T9
    mov    rdx, \M0
    mulx   \T0, \T1, \M1     // T0:T1 = A0*B0
    mov    \C, \T1           // C0_final
    mulx   \T1, \T2, 8\M1    // T1:T2 = A0*B1
    add    \T0, \T2        
    mulx   \T2, \T3, 16\M1   // T2:T3 = A0*B2
    adc    \T1, \T3         
    mulx   \T3, \T4, 24\M1   // T3:T4 = A0*B3
    adc    \T2, \T4        
    mov    rdx, 8\M0
    adc    \T3, 0         

    mulx   \T5, \T4, \M1     // T5:T4 = A1*B0
    mulx   \T6, \T7, 8\M1    // T6:T7 = A1*B1
    add    \T5, \T7        
    mulx   \T7, \T8, 16\M1   // T7:T8 = A1*B2
    adc    \T6, \T8        
    mulx   \T8, \T9, 24\M1   // T8:T9 = A1*B3
    adc    \T7, \T9        
    adc    \T8, 0         

    add    \T4, \T0
    mov    8\C, \T4          // C1_final
    adc    \T5, \T1
    adc    \T6, \T2
    adc    \T7, \T3
    mov    rdx, 16\M0
    adc    \T8, 0

    mulx   \T1, \T0, \M1     // T1:T0 = A2*B0
    mulx   \T2, \T3, 8\M1    // T2:T3 = A2*B1
    add    \T1, \T3        
    mulx   \T3, \T4, 16\M1   // T3:T4 = A2*B2
    adc    \T2, \T4        
    mulx   \T4,\T9, 24\M1    // T3:T4 = A2*B3
    adc    \T3, \T9        
    mov    rdx, 24\M0
    adc    \T4, 0          

    add    \T0, \T5
    mov    16\C, \T0         // C2_final
    adc    \T1, \T6
    adc    \T2, \T7
    adc    \T3, \T8
    adc    \T4, 0

    mulx   \T5, \T0, \M1     // T5:T0 = A3*B0
    mulx   \T6, \T7, 8\M1    // T6:T7 = A3*B1
    add    \T5, \T7        
    mulx   \T7, \T8, 16\M1   // T7:T8 = A3*B2
    adc    \T6, \T8        
    mulx   \T8, \T9, 24\M1   // T8:T9 = A3*B3
    adc    \T7, \T9         
    adc    \T8, 0         

    add    \T1, \T0
    mov    24\C, \T1         // C3_final
    adc    \T2, \T5
    mov    32\C, \T2         // C4_final
    adc    \T3, \T6
    mov    40\C, \T3         // C5_final
    adc    \T4, \T7
    mov    48\C, \T4         // C6_final
    adc    \T8, 0
    mov    56\C, \T8         // C7_final
.endm
#endif


//*****************************************************************************
//  546-bit multiplication using Karatsuba (one level), schoolbook (two levels)
//***************************************************************************** 
.global fmt(mul546_asm)
fmt(mul546_asm):    
    push   r12
    push   r13 
    push   r14 
    push   r15
    mov    rcx, reg_p3 

    // [rsp] <- AH + AL, rax <- mask
    xor    rax, rax
    mov    r8, [reg_p1]
    mov    r9, [reg_p1+8]
    mov    r10, [reg_p1+16]
    mov    r11, [reg_p1+24] 
    mov    r12, [reg_p1+32] 
    push   rbx  
    push   rbp
    sub    rsp, 160
    add    r8, [reg_p1+40]
    adc    r9, [reg_p1+48]
    adc    r10, [reg_p1+56]
    adc    r11, [reg_p1+64]
    adc    r12, 0
    sbb    rax, 0
    mov    [rsp], r8
    mov    [rsp+8], r9
    mov    [rsp+16], r10
    mov    [rsp+24], r11
    mov    [rsp+32], r12

    // [rsp+40] <- BH + BL, rdx <- mask
    xor    rdx, rdx
    mov    r8, [reg_p2]
    mov    r15, [reg_p2+8]
    mov    rbx, [reg_p2+16]
    mov    r13, [reg_p2+24] 
    mov    r14, [reg_p2+32]    
    add    r8, [reg_p2+40]
    adc    r15, [reg_p2+48]
    adc    rbx, [reg_p2+56]
    adc    r13, [reg_p2+64]
    adc    r14, 0
    sbb    rdx, 0
    mov    [rsp+40], r8
    mov    [rsp+48], r15
    mov    [rsp+56], rbx
    mov    [rsp+64], r13
    mov    [rsp+72], r14     
    
    // [rcx] <- masked (BH + BL)
    and    r8, rax
    and    r15, rax
    and    rbx, rax
    and    r13, rax
    and    r14, rax    
    mov    [rcx], r8

    // r8-r12 <- masked (AH + AL)
    mov    r8, [rsp]
    and    r8, rdx
    and    r9, rdx
    and    r10, rdx
    and    r11, rdx
    and    r12, rdx

    // [rcx+80] <- masked (AH + AL) + masked (BH + BL)
    mov    rax, [rcx]
    add    r8, rax
    adc    r9, r15
    adc    r10, rbx
    adc    r11, r13
    adc    r12, r14        
    mov    [rcx+80], r8
    mov    [rcx+88], r9
    mov    [rcx+96], r10
    mov    [rcx+104], r11
    mov    [rcx+112], r12

    // [rcx] <- AL x BL
    MUL320_SCHOOL  [reg_p1], [reg_p2], [rcx], r8, r9, r10, r11, r12, r13, r14, r15     // Result C0-C4 

    // [rsp+80] <- (AH+AL) x (BH+BL), low part 
    MUL320_SCHOOL  [rsp], [rsp+40], [rsp+80], r8, r9, r10, r11, r12, r13, r14, r15

    // [rsp] <- AH x BH 
    MUL256_SCHOOL  [reg_p1+40], [reg_p2+40], [rsp], r8, r9, r10, r11, r12, r13, r14, r15, rbx, rbp
    
    // r8-r12 <- (AH+AL) x (BH+BL), final step
    mov    r8, [rcx+80]
    mov    r9, [rcx+88]
    mov    r10, [rcx+96]
    mov    r11, [rcx+104]
    mov    r12, [rcx+112]
    mov    rax, [rsp+120]
    add    r8, rax
    mov    rax, [rsp+128]
    adc    r9, rax
    mov    rax, [rsp+136]
    adc    r10, rax
    mov    rax, [rsp+144]
    adc    r11, rax
    mov    rax, [rsp+152]
    adc    r12, rax
    
    // rdi,rdx,rbx,r13,r14,r8-r12 <- (AH+AL) x (BH+BL) - ALxBL
    mov    rdi, [rsp+80]
    sub    rdi, [rcx]
    mov    rdx, [rsp+88]
    sbb    rdx, [rcx+8]
    mov    rbx, [rsp+96]
    sbb    rbx, [rcx+16]
    mov    r13, [rsp+104]
    sbb    r13, [rcx+24]
    mov    r14, [rsp+112]     
    sbb    r14, [rcx+32]  
    sbb    r8, [rcx+40]
    sbb    r9, [rcx+48]
    sbb    r10, [rcx+56]
    sbb    r11, [rcx+64]
    sbb    r12, [rcx+72]
    
    // rdi,rdx,rbx,r13,r14,r8-r12 <- (AH+AL) x (BH+BL) - ALxBL - AHxBH
    sub    rdi, [rsp]
    sbb    rdx, [rsp+8]
    sbb    rbx, [rsp+16]
    sbb    r13, [rsp+24]
    sbb    r14, [rsp+32]  
    sbb    r8, [rsp+40]
    sbb    r9, [rsp+48]
    sbb    r10, [rsp+56]
    sbb    r11, 0
    sbb    r12, 0
    
    mov    rax, [rcx+40]
    add    rax, rdi
    mov    [rcx+40], rax    // Result C5-C9
    mov    rax, [rcx+48]
    adc    rax, rdx
    mov    [rcx+48], rax 
    mov    rax, [rcx+56]
    adc    rax, rbx
    mov    [rcx+56], rax 
    mov    rax, [rcx+64]
    adc    rax, r13
    mov    [rcx+64], rax 
    mov    rax, [rcx+72]
    adc    rax, r14           
    mov    [rcx+72], rax 
    mov    rax, [rsp]
    adc    r8, rax 
    mov    [rcx+80], r8    // Result C10-C19
    mov    rax, [rsp+8]
    adc    r9, rax
    mov    [rcx+88], r9 
    mov    rax, [rsp+16]
    adc    r10, rax
    mov    [rcx+96], r10 
    mov    rax, [rsp+24]
    adc    r11, rax
    mov    [rcx+104], r11 
    mov    rax, [rsp+32]
    adc    r12, rax
    mov    [rcx+112], r12 
    mov    r8, [rsp+40]
    mov    r9, [rsp+48]
    mov    r10, [rsp+56]
    adc    r8, 0
    adc    r9, 0
    adc    r10, 0
    add    rsp, 160   
    mov    [rcx+120], r8 
    mov    [rcx+128], r9 
    mov    [rcx+136], r10 
      
    pop    rbp
    pop    rbx
    pop    r15
    pop    r14
    pop    r13
    pop    r12
    ret

#else

//***********************************************************************
//  Integer multiplication
//  Based on Karatsuba method
//  Operation: c [reg_p3] = a [reg_p1] * b [reg_p2]
//  NOTE: a=c or b=c are not allowed
//***********************************************************************
.global fmt(mul546_asm)
fmt(mul546_asm):

  ret

# error "CONFIGURATION NOT SUPPORTED. TRY USE_MULX=TRUE"

#endif

#ifdef _MULX_

///////////////////////////////////////////////////////////////// MACRO
// Schoolbook integer multiplication
// Inputs:  memory pointers M0 and M1
// Outputs: regs T0:T7
// Temps:   regs T8
/////////////////////////////////////////////////////////////////

#ifdef _ADX_
.macro MUL128x320_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7, TT
    mov    rdx, \M0
    mulx   \T1, \T0, \M1       // T0 <- C0_final    
    mulx   \T2, \T4, 8\M1
    xor    rax, rax
    mulx   \T3, \T5, 16\M1 
    adox   \T1, \T4               
    adox   \T2, \T5     
    mulx   \T4, \T7, 24\M1
    adox   \T3, \T7         
    mulx   \T5, \T6, 32\M1 
    adox   \T4, \T6           
    adox   \T5, \TT   
    
    mov    rdx, 8\M0 
    mulx   \T7, \T6, \M1 
    adcx   \T1, \T6            // T1 <- C1_final 
    adcx   \T2, \T7    
    mulx   \T6, \T7, 8\M1
    adox   \T2, \T7  
    adcx   \T3, \T6        
    mulx   \T6, \T7, 16\M1
    adox   \T3, \T7
    adcx   \T4, \T6     
    mulx   \T6, \T7, 24\M1
    adox   \T4, \T7     
    adcx   \T5, \T6  
    mulx   \T6, \T7, 32\M1 
    adox   \T5, \T7          
    adox   \T6, rax
.endm

.macro MUL64x320_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7
    mov    rdx, \M0
    mulx   \T1, \T0, \M1       // T0 <- C0_final    
    mulx   \T2, \T4, 8\M1
    xor    rax, rax
    mulx   \T3, \T5, 16\M1 
    adox   \T1, \T4               
    adox   \T2, \T5     
    mulx   \T4, \T7, 24\M1
    adox   \T3, \T7         
    mulx   \T5, \T6, 32\M1 
    adox   \T4, \T6           
    adox   \T5, rax
.endm

#else

.macro MUL128x320_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7, TT
    mov    rdx, \M0
    mulx   \T1, \T0, \M1       // T0 <- C0_final 
    mulx   \T2, \T3, 8\M1
    add    \T1, \T3               
    adc    \T2, 0  

    mov    rdx, 8\M0   
    xor    \T5, \T5
    mulx   \T3, \T4, \M1 
    add    \T1, \T4               
    adc    \T2, \T3  
    adc    \T5, 0  
      
    xor    \T6, \T6
    mulx   \T3, \T4, 8\M1
    add    \T2, \T4  
    adc    \T3, \T5           
    adc    \T6, 0 
        
    mov    rdx, \M0         
    mulx   \T4, \T5, 16\M1 
    add    \T2, \T5  
    adc    \T3, \T4           
    adc    \T6, 0  
        
    xor    \T7, \T7        
    mulx   \T4, \T5, 24\M1 
    add    \T3, \T5  
    adc    \T4, \T6           
    adc    \T7, 0  

    mov    rdx, 8\M0 
    mulx   \T5, \T6, 16\M1 
    add    \T3, \T6               
    adc    \T4, \T5  
    adc    \T7, 0    
        
    xor    \T6, \T6        
    mulx   \T5, rax, 24\M1 
    add    \T4, rax  
    adc    \T5, \T7           
    adc    \T6, 0  
        
    mov    rdx, 32\M1        
    mulx   \T7, rax, \M0 
    add    \T4, rax  
    adc    \T5, \T7           
    adc    \T6, 0      
               
    mulx   rax, \T7, 8\M0 
    add    \T5, \T7  
    adc    \T6, rax

    add    \T5, \TT  
    adc    \T6, 0
.endm

.macro MUL64x320_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7
    mov    rdx, \M0
    mulx   \T1, \T0, \M1       // T0 <- C0_final 
    mulx   \T2, \T3, 8\M1
    add    \T1, \T3               
    adc    \T2, 0  
  
    mulx   \T3, \T4, 16\M1 
    add    \T2, \T4  
    adc    \T3, 0  
      
    mulx   \T4, \T5, 24\M1
    add    \T3, \T5          
    adc    \T4, 0 
                
    mulx   \T5, \T6, 32\M1 
    add    \T4, \T6           
    adc    \T5, 0
.endm  
#endif

  
//**************************************************************************************
//  Montgomery reduction
//  Based on method described in Faz-Hernandez et al. https://eprint.iacr.org/2017/1015  
//  Operation: c [reg_p2] = a [reg_p1]
//  NOTE: a=c is not allowed
//************************************************************************************** 
.global fmt(rdc546_asm)
fmt(rdc546_asm):
    push   r12
    push   r13 
    push   r14 
    push   r15 	
    xor    rcx, rcx

    // a[0-1] x p546p1_nz --> result: r8:r14 
    MUL128x320_SCHOOL [reg_p1], [rip+fmt(p546p1)+32], r8, r9, r10, r11, r12, r13, r14, r15, rcx     
	
    xor    rcx, rcx
    add    r8, [reg_p1+32]  
    adc    r9, [reg_p1+40]  
    adc    r10, [reg_p1+48]   
    adc    r11, [reg_p1+56]   
    adc    r12, [reg_p1+64]   
    adc    r13, [reg_p1+72]   
    adc    r14, [reg_p1+80]
	adc    rcx, 0  
    mov    [reg_p1+32], r8  
    mov    [reg_p1+40], r9  
    mov    [reg_p1+48], r10  
    mov    [reg_p1+56], r11  
    mov    [reg_p1+64], r12  
    mov    [reg_p1+72], r13  
    mov    [reg_p1+80], r14

    // a[2-3] x p546p1_nz --> result: r8:r14
    MUL128x320_SCHOOL [reg_p1+16], [rip+fmt(p546p1)+32], r8, r9, r10, r11, r12, r13, r14, r15, rcx 

    xor    rcx, rcx
    add    r8, [reg_p1+48]  
    adc    r9, [reg_p1+56]  
    adc    r10, [reg_p1+64]   
    adc    r11, [reg_p1+72]  
    adc    r12, [reg_p1+80]   
    adc    r13, [reg_p1+88]   
    adc    r14, [reg_p1+96] 
    adc    rcx, 0
    mov    [reg_p1+48], r8  
    mov    [reg_p1+56], r9  
    mov    [reg_p1+64], r10  
    mov    [reg_p1+72], r11   
    mov    [reg_p1+80], r12  
    mov    [reg_p1+88], r13  
    mov    [reg_p1+96], r14

    // a[4-5] x p546p1_nz --> result: r8:r14
    MUL128x320_SCHOOL [reg_p1+32], [rip+fmt(p546p1)+32], r8, r9, r10, r11, r12, r13, r14, r15, rcx 

    xor    rcx, rcx
    add    r8, [reg_p1+64]  
    adc    r9, [reg_p1+72]  
    adc    r10, [reg_p1+80]   
    adc    r11, [reg_p1+88]  
    adc    r12, [reg_p1+96]   
    adc    r13, [reg_p1+104]   
    adc    r14, [reg_p1+112] 
    adc    rcx, 0
    mov    [reg_p1+64], r8 
    mov    [reg_p2], r9         // C0_final 
    mov    [reg_p1+80], r10  
    mov    [reg_p1+88], r11   
    mov    [reg_p1+96], r12  
    mov    [reg_p1+104], r13  
    mov    [reg_p1+112], r14

    // a[6-7] x p546p1_nz --> result: r8:r14
    MUL128x320_SCHOOL [reg_p1+48], [rip+fmt(p546p1)+32], r8, r9, r10, r11, r12, r13, r14, r15, rcx 

    xor    rcx, rcx
    add    r8, [reg_p1+80]  
    adc    r9, [reg_p1+88]  
    adc    r10, [reg_p1+96]   
    adc    r11, [reg_p1+104]  
    adc    r12, [reg_p1+112]   
    adc    r13, [reg_p1+120]   
    adc    r14, [reg_p1+128]
    adc    rcx, [reg_p1+136]
    mov    [reg_p2+8], r8       // C1_final
    mov    [reg_p2+16], r9      // C2_final
    mov    [reg_p1+96], r10  
    mov    [reg_p1+104], r11   
    mov    [reg_p1+112], r12  
    mov    [reg_p1+120], r13  
    mov    [reg_p1+128], r14

    // a[8-9] x p546p1_nz --> result: r8:r13
    MUL64x320_SCHOOL [reg_p1+64], [rip+fmt(p546p1)+32], r8, r9, r10, r11, r12, r13, r14, r15
    
    // Final result C3:C8
    add    r8, [reg_p1+96]  
    adc    r9, [reg_p1+104]  
    adc    r10, [reg_p1+112]   
    adc    r11, [reg_p1+120]  
    adc    r12, [reg_p1+128]   
    adc    r13, rcx
    mov    [reg_p2+24], r8
    mov    [reg_p2+32], r9  
    mov    [reg_p2+40], r10   
    mov    [reg_p2+48], r11  
    mov    [reg_p2+56], r12  
    mov    [reg_p2+64], r13

    pop    r15
    pop    r14
    pop    r13
    pop    r12
    ret

  #else
  
//***********************************************************************
//  Montgomery reduction
//  Based on comba method
//  Operation: c [reg_p2] = a [reg_p1]
//  NOTE: a=c is not allowed
//*********************************************************************** 
.global fmt(rdc546_asm)
fmt(rdc546_asm):

  ret

# error "CONFIGURATION NOT SUPPORTED. TRY USE_MULX=TRUE"

  #endif

//***********************************************************************
//  546-bit multiprecision addition
//  Operation: c [reg_p3] = a [reg_p1] + b [reg_p2]
//*********************************************************************** 
.global fmt(mp_add546_asm)
fmt(mp_add546_asm):  
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    rax, [reg_p1+32]
  add    r8, [reg_p2] 
  adc    r9, [reg_p2+8] 
  adc    r10, [reg_p2+16] 
  adc    r11, [reg_p2+24] 
  adc    rax, [reg_p2+32] 
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], rax

  mov    r8, [reg_p1+40]
  mov    r9, [reg_p1+48] 
  mov    r10, [reg_p1+56]
  mov    r11, [reg_p1+64] 
  mov    rax, [reg_p1+72] 
  adc    r8, [reg_p2+40] 
  adc    r9, [reg_p2+48]
  adc    r10, [reg_p2+56] 
  adc    r11, [reg_p2+64]
  mov    [reg_p3+40], r8
  mov    [reg_p3+48], r9
  mov    [reg_p3+56], r10
  mov    [reg_p3+64], r11
  ret


//***********************************************************************
//  2x546-bit multiprecision subtraction/addition
//  Operation: c [x2] = a [x0] - b [x1]. If c < 0, add p546*2^576
//*********************************************************************** 
.global fmt(mp_subadd546x2_asm)
fmt(mp_subadd546x2_asm):
  push   r12
  push   r13 
  push   r14 
  push   r15
  xor    rax, rax
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  mov    rcx, [reg_p1+32]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    rcx, [reg_p2+32] 
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], rcx

  mov    r8, [reg_p1+40]
  mov    r9, [reg_p1+48]
  mov    r10, [reg_p1+56] 
  mov    r11, [reg_p1+64]
  sbb    r8, [reg_p2+40] 
  sbb    r9, [reg_p2+48] 
  sbb    r10, [reg_p2+56]
  sbb    r11, [reg_p2+64]
  mov    [reg_p3+40], r8
  mov    [reg_p3+48], r9
  mov    [reg_p3+56], r10
  mov    [reg_p3+64], r11
  
  mov    r8, [reg_p1+72]
  mov    r9, [reg_p1+80] 
  mov    r10, [reg_p1+88]
  mov    r11, [reg_p1+96]
  mov    rcx, [reg_p1+104]
  sbb    r8, [reg_p2+72]
  sbb    r9, [reg_p2+80]
  sbb    r10, [reg_p2+88] 
  sbb    r11, [reg_p2+96] 
  sbb    rcx, [reg_p2+104]
  mov    [reg_p3+72], r8 
  mov    [reg_p3+80], r9
  mov    [reg_p3+88], r10
  mov    [reg_p3+96], r11
  mov    [reg_p3+104], rcx
  
  mov    r8, [reg_p1+112]
  mov    r9, [reg_p1+120]
  mov    r10, [reg_p1+128]
  mov    r11, [reg_p1+136]
  sbb    r8, [reg_p2+112] 
  sbb    r9, [reg_p2+120] 
  sbb    r10, [reg_p2+128] 
  sbb    r11, [reg_p2+136]
  sbb    rax, 0
  
  // Add p546 anded with the mask in rax 
  mov    r12, [rip+fmt(p546)]
  mov    r13, [rip+fmt(p546)+32]
  mov    r14, [rip+fmt(p546)+40]
  mov    r15, [rip+fmt(p546)+48]
  mov    rdi, [rip+fmt(p546)+56]
  mov    rsi, [rip+fmt(p546)+64]
  and    r12, rax
  and    r13, rax
  and    r14, rax
  and    r15, rax
  and    rdi, rax
  and    rsi, rax
  mov    rax, [reg_p3+72]
  add    rax, r12
  mov    [reg_p3+72], rax
  mov    rax, [reg_p3+80]
  adc    rax, r12
  mov    [reg_p3+80], rax
  mov    rax, [reg_p3+88]
  adc    rax, r12
  mov    [reg_p3+88], rax
  adc    r12, [reg_p3+96]
  adc    r13, [reg_p3+104]
  mov    [reg_p3+96], r12
  mov    [reg_p3+104], r13
  adc    r8, r14
  adc    r9, r15
  adc    r10, rdi
  adc    r11, rsi
  
  mov    [reg_p3+112], r8
  mov    [reg_p3+120], r9
  mov    [reg_p3+128], r10
  mov    [reg_p3+136], r11
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret


//***********************************************************************
//  Double 2x546-bit multiprecision subtraction
//  Operation: c [reg_p3] = c [reg_p3] - a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global fmt(mp_dblsub546x2_asm)
fmt(mp_dblsub546x2_asm):
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
  setc   al 
  bt     rcx, 0  
  sbb    r8, [reg_p2+48] 
  sbb    r9, [reg_p2+56]
  sbb    r10, [reg_p2+64] 
  sbb    r11, [reg_p2+72] 
  sbb    r12, [reg_p2+80] 
  sbb    r13, [reg_p2+88]
  setc   cl 
  mov    [reg_p3+48], r8
  mov    [reg_p3+56], r9
  mov    [reg_p3+64], r10
  mov    [reg_p3+72], r11
  mov    [reg_p3+80], r12
  mov    [reg_p3+88], r13
  
  mov    r8, [reg_p3+96]
  mov    r9, [reg_p3+104]
  mov    r10, [reg_p3+112]
  mov    r11, [reg_p3+120]
  mov    r12, [reg_p3+128]
  mov    r13, [reg_p3+136]
  bt     rax, 0  
  sbb    r8, [reg_p1+96] 
  sbb    r9, [reg_p1+104] 
  sbb    r10, [reg_p1+112] 
  sbb    r11, [reg_p1+120]
  sbb    r12, [reg_p1+128] 
  sbb    r13, [reg_p1+136]
  bt     rcx, 0  
  sbb    r8, [reg_p2+96] 
  sbb    r9, [reg_p2+104] 
  sbb    r10, [reg_p2+112] 
  sbb    r11, [reg_p2+120]
  sbb    r12, [reg_p2+128] 
  sbb    r13, [reg_p2+136]
  mov    [reg_p3+96], r8
  mov    [reg_p3+104], r9
  mov    [reg_p3+112], r10
  mov    [reg_p3+120], r11
  mov    [reg_p3+128], r12
  mov    [reg_p3+136], r13
  
  pop    r13
  pop    r12
  ret