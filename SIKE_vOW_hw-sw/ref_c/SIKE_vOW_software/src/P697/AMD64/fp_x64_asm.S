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
// Abstract: field arithmetic in x64 assembly for P697 on Linux 
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
.global fmt(fpadd697_asm)
fmt(fpadd697_asm):
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
  mov    rax, [reg_p1+72]
  mov    rdi, [reg_p1+80]
  add    r8, [reg_p2] 
  adc    r9, [reg_p2+8] 
  adc    r10, [reg_p2+16] 
  adc    r11, [reg_p2+24] 
  adc    r12, [reg_p2+32] 
  adc    r13, [reg_p2+40] 
  adc    r14, [reg_p2+48] 
  adc    r15, [reg_p2+56]
  adc    rcx, [reg_p2+64]
  adc    rax, [reg_p2+72]
  adc    rdi, [reg_p2+80] 
  mov    [reg_p3+72], rax

  mov    rax, [rip+fmt(p697x2)]
  sub    r8, rax
  mov    rax, [rip+fmt(p697x2)+8]
  sbb    r9, rax
  sbb    r10, rax
  sbb    r11, rax
  sbb    r12, rax
  mov    rax, [rip+fmt(p697x2)+40]
  sbb    r13, rax
  mov    rax, [rip+fmt(p697x2)+48]
  sbb    r14, rax
  mov    rax, [rip+fmt(p697x2)+56]
  sbb    r15, rax
  mov    rax, [rip+fmt(p697x2)+64]
  sbb    rcx, rax
  mov    rsi, [reg_p3+72]
  sbb    rsi, [rip+fmt(p697x2)+72]
  mov    rax, [rip+fmt(p697x2)+80]
  sbb    rdi, rax
  mov    [reg_p3+64], rcx
  mov    [reg_p3+72], rsi
  mov    rax, 0
  sbb    rax, 0
  
  mov    rcx, [rip+fmt(p697x2)]
  and    rcx, rax
  mov    rsi, [rip+fmt(p697x2)+8]
  and    rsi, rax
  
  add    r8, rcx  
  adc    r9, rsi 
  adc    r10, rsi 
  adc    r11, rsi
  adc    r12, rsi
  mov    [reg_p3], r8 
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11 
  mov    [reg_p3+32], r12  
  setc   cl
  
  mov    rsi, [rip+fmt(p697x2)+40]
  and    rsi, rax
  mov    r8, [rip+fmt(p697x2)+48]
  and    r8, rax
  mov    r9, [rip+fmt(p697x2)+56]
  and    r9, rax
  mov    r10, [rip+fmt(p697x2)+64]
  and    r10, rax
  mov    r11, [rip+fmt(p697x2)+72]
  and    r11, rax
  mov    r12, [rip+fmt(p697x2)+80]
  and    r12, rax
  
  bt     rcx, 0
  adc    r13, rsi  
  adc    r14, r8
  adc    r15, r9
  mov    rax, [reg_p3+64]
  mov    rcx, [reg_p3+72]
  adc    r10, rax 
  adc    r11, rcx
  adc    r12, rdi
  mov    [reg_p3+40], r13
  mov    [reg_p3+48], r14
  mov    [reg_p3+56], r15  
  mov    [reg_p3+64], r10
  mov    [reg_p3+72], r11
  mov    [reg_p3+80], r12

  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret


//***********************************************************************
//  Field subtraction
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global fmt(fpsub697_asm)
fmt(fpsub697_asm):
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
  mov    rax, [reg_p1+72]
  mov    rdi, [reg_p1+80]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40] 
  sbb    r14, [reg_p2+48] 
  sbb    r15, [reg_p2+56]
  sbb    rcx, [reg_p2+64]
  sbb    rax, [reg_p2+72]
  sbb    rdi, [reg_p2+80]
  mov    [reg_p3+64], rcx
  mov    [reg_p3+72], rax
  mov    rax, 0
  sbb    rax, 0
    
  mov    rcx, [rip+fmt(p697x2)]
  and    rcx, rax
  mov    rsi, [rip+fmt(p697x2)+8]
  and    rsi, rax
  
  add    r8, rcx  
  adc    r9, rsi 
  adc    r10, rsi 
  adc    r11, rsi
  adc    r12, rsi
  mov    [reg_p3], r8 
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11 
  mov    [reg_p3+32], r12  
  setc   cl
  
  mov    rsi, [rip+fmt(p697x2)+40]
  and    rsi, rax
  mov    r8, [rip+fmt(p697x2)+48]
  and    r8, rax
  mov    r9, [rip+fmt(p697x2)+56]
  and    r9, rax
  mov    r10, [rip+fmt(p697x2)+64]
  and    r10, rax
  mov    r11, [rip+fmt(p697x2)+72]
  and    r11, rax
  mov    r12, [rip+fmt(p697x2)+80]
  and    r12, rax
  
  bt     rcx, 0
  adc    r13, rsi  
  adc    r14, r8
  adc    r15, r9
  mov    rax, [reg_p3+64]
  mov    rcx, [reg_p3+72]
  adc    r10, rax  
  adc    r11, rcx 
  adc    r12, rdi
  mov    [reg_p3+40], r13
  mov    [reg_p3+48], r14
  mov    [reg_p3+56], r15 
  mov    [reg_p3+64], r10
  mov    [reg_p3+72], r11
  mov    [reg_p3+80], r12
  
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret 


///////////////////////////////////////////////////////////////// MACRO
.macro SUB697_PX  P0
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
  mov    rcx, [reg_p1+72]
  mov    rdi, [reg_p1+80]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40]
  sbb    r14, [reg_p2+48] 
  sbb    r15, [reg_p2+56] 
  sbb    rax, [reg_p2+64] 
  sbb    rcx, [reg_p2+72] 
  sbb    rdi, [reg_p2+80] 

  mov    rsi, [rip+\P0]
  add    r8, rsi  
  mov    rsi, [rip+\P0+8]
  adc    r9, rsi  
  adc    r10, rsi 
  adc    r11, rsi 
  adc    r12, rsi  
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9 
  mov    [reg_p3+16], r10 
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], r12 
  mov    r8, [rip+\P0+40]
  mov    r9, [rip+\P0+48]
  mov    r10, [rip+\P0+56] 
  adc    r13, r8   
  adc    r14, r9 
  adc    r15, r10  
  mov    r8, [rip+\P0+64]
  mov    r9, [rip+\P0+72]
  mov    r10, [rip+\P0+80]
  adc    r8, rax 
  adc    r9, rcx  
  adc    r10, rdi 
  mov    [reg_p3+40], r13 
  mov    [reg_p3+48], r14
  mov    [reg_p3+56], r15 
  mov    [reg_p3+64], r8
  mov    [reg_p3+72], r9
  mov    [reg_p3+80], r10
  
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  .endm


//***********************************************************************
//  Multiprecision subtraction with correction with 2*p697
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 2*p697
//*********************************************************************** 
.global fmt(mp_sub697_p2_asm)
fmt(mp_sub697_p2_asm):

  SUB697_PX  fmt(p697x2)
  ret


//***********************************************************************
//  Multiprecision subtraction with correction with 4*p697
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 4*p697
//*********************************************************************** 
.global fmt(mp_sub697_p4_asm)
fmt(mp_sub697_p4_asm):

  SUB697_PX  fmt(p697x4)
  ret


#ifdef _MULX_

/////////////////////////////////////////////////////////////////////////// MACRO
// Schoolbook integer multiplication
// Inputs:  memory pointers M0 and M1
// Outputs: memory pointer C
// Temps:   stack space for two 64-bit values (case w/o _ADX_), regs T0:T7
///////////////////////////////////////////////////////////////////////////
#ifdef _ADX_

.macro MUL384_SCHOOL M0, M1, C, S, T0, T1, T2, T3, T4, T5, T6, T7 
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
    mulx   \T3, \T7, 40\M1    
    adox   \T5, \T7       
    adox   \T3, rax        
    
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
    mulx   \T5, \T6, 32\M1     
    adcx   \T3, \T5   
    mulx   \T5, rdx, 40\M1
    adcx   \T5, rax 
        
    adox   \T0, \T7  
    adox   \T1, \T6  
    adox   \T3, rdx  
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
    adcx   \T3, \T2  
    mulx   \T2, \T6, 32\M1     
    adcx   \T5, \T2   
    mulx   \T2, rdx, 40\M1     
    adcx   \T2, rax 
         
    adox   \T1, \T7  
    adox   \T3, \T6  
    adox   \T5, rdx 
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
    adcx   \T3, \T4     
    mulx   \T4, \T7, 24\M1   
    adcx   \T5, \T4  
    mulx   \T4, \T6, 32\M1     
    adcx   \T2, \T4   
    mulx   \T4, rdx, 40\M1     
    adcx   \T4, rax
        
    adox   \T3, \T7  
    adox   \T5, \T6  
    adox   \T2, rdx  
    adox   \T4, rax         
    
    mov    rdx, 32\M0 
    mulx   \T6, \T7, \M1 
    xor    rax, rax
    adcx   \T0, \T7 
    mov    32\C, \T0           // C4_final 
    adcx   \T1, \T6     
    mulx   \T6, \T7, 8\M1
    adox   \T1, \T7 
    adcx   \T3, \T6        
    mulx   \T0, \T6, 16\M1 
    adox   \T3, \T6 
    adcx   \T5, \T0     
    mulx   \T0, \T7, 24\M1   
    adcx   \T2, \T0  
    mulx   \T0, \T6, 32\M1     
    adcx   \T4, \T0   
    mulx   \T0, rdx, 40\M1     
    adcx   \T0, rax 
         
    adox   \T5, \T7  
    adox   \T2, \T6  
    adox   \T4, rdx  
    adox   \T0, rax           
    
    mov    rdx, 40\M0 
    mulx   \T6, \T7, \M1 
    xor    rax, rax
    adcx   \T1, \T7 
    mov    40\C, \T1           // C5_final 
    adcx   \T3, \T6     
    mulx   \T6, \T7, 8\M1
    adox   \T3, \T7 
    adcx   \T5, \T6        
    mulx   \T1, \T6, 16\M1
    adox   \T5, \T6 
    adcx   \T2, \T1     
    mulx   \T1, \T7, 24\M1   
    adcx   \T4, \T1  
    mulx   \T1, \T6, 32\M1     
    adcx   \T0, \T1   
    mulx   \T1, rdx, 40\M1     
    adcx   \T1, rax 
         
    adox   \T2, \T7 
    adox   \T4, \T6 
    adox   \T0, rdx 
    adox   \T1, rax 
    mov    48\C, \T3 
    mov    56\C, \T5 
    mov    64\C, \T2 
    mov    72\C, \T4
    mov    80\C, \T0 
    mov    88\C, \T1 
.endm

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

#else

.macro MUL384_SCHOOL M0, M1, C, S, T0, T1, T2, T3, T4, T5, T6, T7 
    mov    rdx, \M0
    mulx   \T0, \T1, \M1    
    mulx   \T2, \T3, 8\M1
    mov    \C, \T1             // C0_final 
    xor    rax, rax
    mulx   \T4, \T5, 16\M1 
    add    \T0, \T3               
    adc    \T2, \T5     
    mulx   \T1, \T3, 24\M1
    adc    \T4, \T3         
    mulx   \T5, \T6, 32\M1 
    adc    \T1, \T6        
    mulx   \T3, \T7, 40\M1    
    adc    \T5, \T7       
    adc    \T3, rax        
    
    mov    rdx, 8\M0 
    mulx   \T6, \T7, \M1 
    add    \T0, \T7 
    mov    8\C, \T0            // C1_final 
    adc    \T2, \T6     
    mulx   \T6, \T7, 8\M1
    mov    \S, \T7             // store T7
    adc    \T4, \T6        
    mulx   \T0, \T6, 16\M1   
    mov    8\S, \T6            // store T6 
    adc    \T0, \T1     
    mulx   \T1, \T7, 24\M1   
    adc    \T1, \T5  
    mulx   \T5, \T6, 32\M1     
    adc    \T3, \T5   
    mulx   \T5, rdx, 40\M1
    adc    \T5, rax 
        
    xor    rax, rax
    add    \T2, \S 
    adc    \T4, 8\S  
    adc    \T0, \T7  
    adc    \T1, \T6  
    adc    \T3, rdx  
    adc    \T5, rax         
    
    mov    rdx, 16\M0 
    mulx   \T6, \T7, \M1 
    add    \T2, \T7 
    mov    16\C, \T2           // C2_final 
    adc    \T4, \T6     
    mulx   \T6, \T7, 8\M1
    mov    \S, \T7             // store T7
    adc    \T0, \T6        
    mulx   \T2, \T6, 16\M1   
    mov    8\S, \T6            // store T6 
    adc    \T1, \T2     
    mulx   \T2, \T7, 24\M1   
    adc    \T3, \T2  
    mulx   \T2, \T6, 32\M1     
    adc    \T5, \T2   
    mulx   \T2, rdx, 40\M1     
    adc    \T2, rax 
        
    xor    rax, rax
    add    \T4, \S 
    adc    \T0, 8\S  
    adc    \T1, \T7  
    adc    \T3, \T6  
    adc    \T5, rdx 
    adc    \T2, rax           
    
    mov    rdx, 24\M0 
    mulx   \T6, \T7, \M1 
    add    \T4, \T7 
    mov    24\C, \T4           // C3_final 
    adc    \T0, \T6     
    mulx   \T6, \T7, 8\M1
    mov    \S, \T7             // store T7
    adc    \T1, \T6        
    mulx   \T4, \T6, 16\M1   
    mov    8\S, \T6            // store T6 
    adc    \T3, \T4     
    mulx   \T4, \T7, 24\M1   
    adc    \T5, \T4  
    mulx   \T4, \T6, 32\M1     
    adc    \T2, \T4   
    mulx   \T4, rdx, 40\M1     
    adc    \T4, rax
        
    xor    rax, rax
    add    \T0, \S 
    adc    \T1, 8\S  
    adc    \T3, \T7  
    adc    \T5, \T6  
    adc    \T2, rdx  
    adc    \T4, rax         
    
    mov    rdx, 32\M0 
    mulx   \T6, \T7, \M1 
    add    \T0, \T7 
    mov    32\C, \T0           // C4_final 
    adc    \T1, \T6     
    mulx   \T6, \T7, 8\M1
    mov    \S, \T7             // store T7
    adc    \T3, \T6        
    mulx   \T0, \T6, 16\M1   
    mov    8\S, \T6            // store T6 
    adc    \T5, \T0     
    mulx   \T0, \T7, 24\M1   
    adc    \T2, \T0  
    mulx   \T0, \T6, 32\M1     
    adc    \T4, \T0   
    mulx   \T0, rdx, 40\M1     
    adc    \T0, rax 
        
    xor    rax, rax
    add    \T1, \S 
    adc    \T3, 8\S  
    adc    \T5, \T7  
    adc    \T2, \T6  
    adc    \T4, rdx  
    adc    \T0, rax           
    
    mov    rdx, 40\M0 
    mulx   \T6, \T7, \M1 
    add    \T1, \T7 
    mov    40\C, \T1           // C5_final 
    adc    \T3, \T6     
    mulx   \T6, \T7, 8\M1
    mov    \S, \T7             // store T7
    adc    \T5, \T6        
    mulx   \T1, \T6, 16\M1   
    mov    8\S, \T6            // store T6 
    adc    \T2, \T1     
    mulx   \T1, \T7, 24\M1   
    adc    \T4, \T1  
    mulx   \T1, \T6, 32\M1     
    adc    \T0, \T1   
    mulx   \T1, rdx, 40\M1     
    adc    \T1, rax 
        
    add    \T3, \S 
    adc    \T5, 8\S  
    adc    \T2, \T7 
    adc    \T4, \T6 
    adc    \T0, rdx 
    adc    \T1, 0 
    mov    48\C, \T3 
    mov    56\C, \T5 
    mov    64\C, \T2 
    mov    72\C, \T4
    mov    80\C, \T0 
    mov    88\C, \T1 
.endm

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

#endif


//*****************************************************************************
//  697-bit multiplication using Karatsuba (one level), schoolbook (two levels)
//***************************************************************************** 
.global fmt(mul697_asm)
fmt(mul697_asm):    
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
    mov    r13, [reg_p1+40] 
    push   rbx 
    push   rbp
    sub    rsp, 224
    add    r8, [reg_p1+48]
    adc    r9, [reg_p1+56]
    adc    r10, [reg_p1+64]
    adc    r11, [reg_p1+72]
    adc    r12, [reg_p1+80]
    adc    r13, 0
    sbb    rax, 0
    mov    [rsp], r8
    mov    [rsp+8], r9
    mov    [rsp+16], r10
    mov    [rsp+24], r11
    mov    [rsp+32], r12
    mov    [rsp+40], r13

    // [rsp+48] <- BH + BL, rdx <- mask
    xor    rdx, rdx
    mov    r8, [reg_p2]
    mov    r9, [reg_p2+8]
    mov    rbx, [reg_p2+16]
    mov    rbp, [reg_p2+24] 
    mov    r14, [reg_p2+32]     
    mov    r15, [reg_p2+40]     
    add    r8, [reg_p2+48]
    adc    r9, [reg_p2+56]
    adc    rbx, [reg_p2+64]
    adc    rbp, [reg_p2+72]
    adc    r14, [reg_p2+80]
    adc    r15, 0
    sbb    rdx, 0
    mov    [rsp+48], r8
    mov    [rsp+56], r9
    mov    [rsp+64], rbx
    mov    [rsp+72], rbp
    mov    [rsp+80], r14     
    mov    [rsp+88], r15     
    
    // [rcx] <- masked (BH + BL)
    and    r8, rax
    and    r9, rax
    and    rbx, rax
    and    rbp, rax
    and    r14, rax     
    and    r15, rax     
    mov    [rcx], r8
    mov    [rcx+8], r9

    // r8-r13 <- masked (AH + AL)
    mov    r8, [rsp]
    mov    r9, [rsp+8]
    and    r8, rdx
    and    r9, rdx
    and    r10, rdx
    and    r11, rdx
    and    r12, rdx
    and    r13, rdx

    // [rsp+96] <- masked (AH + AL) + masked (AH + AL)
    mov    rax, [rcx]
    mov    rdx, [rcx+8]
    add    r8, rax
    adc    r9, rdx
    adc    r10, rbx
    adc    r11, rbp
    adc    r12, r14         
    adc    r13, r15         
    mov    [rsp+96], r8
    mov    [rsp+104], r9
    mov    [rsp+112], r10
    mov    [rsp+120], r11

    // [rcx] <- AL x BL
    MUL384_SCHOOL  [reg_p1], [reg_p2], [rcx], [rsp+128], r8, r9, r10, r11, rbx, rbp, r14, r15     // Result C0-C5 

    // [rcx+96] <- (AH+AL) x (BH+BL), low part 
    MUL384_SCHOOL  [rsp], [rsp+48], [rsp+128], [rcx+96], r8, r9, r10, r11, rbx, rbp, r14, r15

    // [rsp] <- AH x BH 
    MUL320_SCHOOL  [reg_p1+48], [reg_p2+48], [rsp], r8, r9, r10, r11, rbx, rbp, r14, r15
    
    // r8-r13 <- (AH+AL) x (BH+BL), final step
    mov    r8, [rsp+96]
    mov    r9, [rsp+104]
    mov    r10, [rsp+112]
    mov    r11, [rsp+120]
    mov    rax, [rsp+176]
    add    r8, rax
    mov    rax, [rsp+184]
    adc    r9, rax
    mov    rax, [rsp+192]
    adc    r10, rax
    mov    rax, [rsp+200]
    adc    r11, rax
    mov    rax, [rsp+208]
    adc    r12, rax
    mov    rax, [rsp+216]
    adc    r13, rax
    
    // rdi,rdx,rbx,rbp,r14,r15,r8-r13 <- (AH+AL) x (BH+BL) - ALxBL
    mov    rdi, [rsp+128]
    sub    rdi, [rcx]
    mov    rdx, [rsp+136]
    sbb    rdx, [rcx+8]
    mov    rbx, [rsp+144]
    sbb    rbx, [rcx+16]
    mov    rbp, [rsp+152]
    sbb    rbp, [rcx+24]
    mov    r14, [rsp+160]     
    sbb    r14, [rcx+32]   
    mov    r15, [rsp+168]     
    sbb    r15, [rcx+40]     
    sbb    r8, [rcx+48]
    sbb    r9, [rcx+56]
    sbb    r10, [rcx+64]
    sbb    r11, [rcx+72]
    sbb    r12, [rcx+80]
    sbb    r13, [rcx+88]
    
    // rdi,rdx,rbx,rbp,r14,r15,r8-r13 <- (AH+AL) x (BH+BL) - ALxBL - AHxBH
    sub    rdi, [rsp]
    sbb    rdx, [rsp+8]
    sbb    rbx, [rsp+16]
    sbb    rbp, [rsp+24]
    sbb    r14, [rsp+32]     
    sbb    r15, [rsp+40]   
    sbb    r8, [rsp+48]
    sbb    r9, [rsp+56]
    sbb    r10, [rsp+64]
    sbb    r11, [rsp+72]
    sbb    r12, 0
    sbb    r13, 0
    
    mov    rax, [rcx+48]
    add    rax, rdi
    mov    [rcx+48], rax    // Result C6-C11
    mov    rax, [rcx+56]
    adc    rax, rdx
    mov    [rcx+56], rax 
    mov    rax, [rcx+64]
    adc    rax, rbx
    mov    [rcx+64], rax 
    mov    rax, [rcx+72]
    adc    rax, rbp
    mov    [rcx+72], rax 
    mov    rax, [rcx+80]
    adc    rax, r14           
    mov    [rcx+80], rax 
    mov    rax, [rcx+88]
    adc    rax, r15             
    mov    [rcx+88], rax
    mov    rax, [rsp]
    adc    r8, rax 
    mov    [rcx+96], r8    // Result C8-C15
    mov    rax, [rsp+8]
    adc    r9, rax
    mov    [rcx+104], r9 
    mov    rax, [rsp+16]
    adc    r10, rax
    mov    [rcx+112], r10 
    mov    rax, [rsp+24]
    adc    r11, rax
    mov    [rcx+120], r11 
    mov    rax, [rsp+32]
    adc    r12, rax
    mov    [rcx+128], r12 
    mov    rax, [rsp+40]
    adc    r13, rax
    mov    [rcx+136], r13
    mov    r8, [rsp+48]
    mov    r9, [rsp+56]
    mov    r10, [rsp+64]
    mov    r11, [rsp+72]
    adc    r8, 0
    adc    r9, 0
    adc    r10, 0
    adc    r11, 0
    add    rsp, 224   
    mov    [rcx+144], r8 
    mov    [rcx+152], r9 
    mov    [rcx+160], r10 
    mov    [rcx+168], r11
     
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
.global fmt(mul697_asm)
fmt(mul697_asm):

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
.macro MUL128x384_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7, T8, TT
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
    mulx   \T7, \T8, 40\M1           
    adox   \T5, \T8         
    adox   \T7, \TT   
    
    mov    rdx, 8\M0 
    mulx   \T8, \T6, \M1 
    adcx   \T1, \T6            // T1 <- C1_final 
    adcx   \T2, \T8    
    mulx   \T6, \T8, 8\M1
    adox   \T2, \T8  
    adcx   \T3, \T6        
    mulx   \T6, \T8, 16\M1
    adox   \T3, \T8
    adcx   \T4, \T6     
    mulx   \T6, \T8, 24\M1
    adox   \T4, \T8     
    adcx   \T5, \T6  
    mulx   \T6, \T8, 32\M1 
    adox   \T5, \T8 
    adcx   \T6, \T7 
    mulx   \T7, \T8, 40\M1
    adcx   \T7, rax  
    adox   \T6, \T8          
    adox   \T7, rax
.endm

.macro MUL64x384_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7
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
    mulx   \T6, \T7, 40\M1 
    adox   \T5, \T7                    
    adox   \T6, rax
.endm

#else

.macro MUL128x384_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7, T8, TT
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
    mulx   \T5, \T8, 24\M1 
    add    \T4, \T8  
    adc    \T5, \T7           
    adc    \T6, 0  
        
    mov    rdx, \M0        
    mulx   \T7, \T8, 32\M1 
    add    \T4, \T8  
    adc    \T5, \T7           
    adc    \T6, 0      
        
    xor    \T7, \T7        
    mulx   \T8, rax, 40\M1 
    add    \T5, rax  
    adc    \T6, \T8          
    adc    \T7, 0  
        
    mov    rdx, 8\M0        
    mulx   \T8, rax, 32\M1 
    add    \T5, rax  
    adc    \T6, \T8         
    adc    \T7, 0   
        
    mov    rdx, 8\M0        
    mulx   \T8, rax, 40\M1 
    add    \T6, rax  
    adc    \T7, \T8 

    add    \T6, \TT  
    adc    \T7, 0 
.endm

.macro MUL64x384_SCHOOL M0, M1, T0, T1, T2, T3, T4, T5, T6, T7
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
                
    mulx   \T6, \T7, 40\M1 
    add    \T5, \T7           
    adc    \T6, 0
.endm  
#endif

  
//**************************************************************************************
//  Montgomery reduction
//  Based on method described in Faz-Hernandez et al. https://eprint.iacr.org/2017/1015  
//  Operation: c [reg_p2] = a [reg_p1]
//  NOTE: a=c is not allowed
//************************************************************************************** 
.global fmt(rdc697_asm)
fmt(rdc697_asm):
    push   r12
    push   r13 
    push   r14 
    push   r15 
    push   rbx 	
    xor    rcx, rcx

    // a[0-1] x p697p1_nz --> result: r8:r15 
    MUL128x384_SCHOOL [reg_p1], [rip+fmt(p697p1)+40], r8, r9, r10, r11, r12, r13, r14, r15, rbx, rcx     
	
    xor    rcx, rcx
    add    r8, [reg_p1+40]  
    adc    r9, [reg_p1+48]  
    adc    r10, [reg_p1+56]   
    adc    r11, [reg_p1+64]   
    adc    r12, [reg_p1+72]   
    adc    r13, [reg_p1+80]   
    adc    r14, [reg_p1+88]   
    adc    r15, [reg_p1+96]
	adc    rcx, 0  
    mov    [reg_p1+40], r8  
    mov    [reg_p1+48], r9  
    mov    [reg_p1+56], r10  
    mov    [reg_p1+64], r11  
    mov    [reg_p1+72], r12  
    mov    [reg_p1+80], r13  
    mov    [reg_p1+88], r14
    mov    [reg_p1+96], r15 

    // a[2-3] x p697p1_nz --> result: r8:r15
    MUL128x384_SCHOOL [reg_p1+16], [rip+fmt(p697p1)+40], r8, r9, r10, r11, r12, r13, r14, r15, rbx, rcx 

    xor    rcx, rcx
    add    r8, [reg_p1+56]  
    adc    r9, [reg_p1+64]  
    adc    r10, [reg_p1+72]   
    adc    r11, [reg_p1+80]  
    adc    r12, [reg_p1+88]   
    adc    r13, [reg_p1+96]   
    adc    r14, [reg_p1+104]    
    adc    r15, [reg_p1+112]
    adc    rcx, 0 
    mov    [reg_p1+56], r8  
    mov    [reg_p1+64], r9  
    mov    [reg_p1+72], r10  
    mov    [reg_p1+80], r11  
    mov    [reg_p1+88], r12  
    mov    [reg_p1+96], r13
    mov    [reg_p1+104], r14 
    mov    [reg_p1+112], r15 

    // a[4-5] x p697p1_nz --> result: r8:r15
    MUL128x384_SCHOOL [reg_p1+32], [rip+fmt(p697p1)+40], r8, r9, r10, r11, r12, r13, r14, r15, rbx, rcx 

    xor    rcx, rcx
    add    r8, [reg_p1+72]  
    adc    r9, [reg_p1+80]  
    adc    r10, [reg_p1+88]   
    adc    r11, [reg_p1+96]  
    adc    r12, [reg_p1+104]   
    adc    r13, [reg_p1+112]   
    adc    r14, [reg_p1+120]    
    adc    r15, [reg_p1+128] 
    adc    rcx, 0 
    mov    [reg_p1+72], r8  
    mov    [reg_p1+80], r9  
    mov    [reg_p1+88], r10  
    mov    [reg_p1+96], r11
    mov    [reg_p1+104], r12 
    mov    [reg_p1+112], r13 
    mov    [reg_p1+120], r14 
    mov    [reg_p1+128], r15 

    // a[6-7] x p697p1_nz --> result: r8:r15
    MUL128x384_SCHOOL [reg_p1+48], [rip+fmt(p697p1)+40], r8, r9, r10, r11, r12, r13, r14, r15, rbx, rcx 

    xor    rcx, rcx 
    add    r8, [reg_p1+88]  
    adc    r9, [reg_p1+96]   
    adc    r10, [reg_p1+104]  
    adc    r11, [reg_p1+112]   
    adc    r12, [reg_p1+120]   
    adc    r13, [reg_p1+128]
    adc    r14, [reg_p1+136]
    adc    r15, [reg_p1+144]
    adc    rcx, 0 
    mov    [reg_p2], r8        // C0_final
    mov    [reg_p2+8], r9      // C1_final
    mov    [reg_p1+104], r10  
    mov    [reg_p1+112], r11
    mov    [reg_p1+120], r12 
    mov    [reg_p1+128], r13 
    mov    [reg_p1+136], r14 
    mov    [reg_p1+144], r15 

    // a[8-9] x p697p1_nz --> result: r8:r15
    MUL128x384_SCHOOL [reg_p1+64], [rip+fmt(p697p1)+40], r8, r9, r10, r11, r12, r13, r14, r15, rbx, rcx 

    xor    rcx, rcx 
    add    r8, [reg_p1+104]  
    adc    r9, [reg_p1+112]   
    adc    r10, [reg_p1+120]   
    adc    r11, [reg_p1+128]
    adc    r12, [reg_p1+136]
    adc    r13, [reg_p1+144]
    adc    r14, [reg_p1+152]
    adc    r15, [reg_p1+160]
    adc    rcx, [reg_p1+168]
    mov    [reg_p2+16], r8      // C3_final
    mov    [reg_p2+24], r9      // C4_final
    mov    [reg_p1+120], r10  
    mov    [reg_p1+128], r11   
    mov    [reg_p1+136], r12  
    mov    [reg_p1+144], r13  
    mov    [reg_p1+152], r14  
    mov    [reg_p1+160], r15

    // a[10] x p697p1_nz --> result: r8:r14
    MUL64x384_SCHOOL [reg_p1+80], [rip+fmt(p697p1)+40], r8, r9, r10, r11, r12, r13, r14, r15
    
    // Final result C5:C10
    add    r8, [reg_p1+120]  
    adc    r9, [reg_p1+128]  
    adc    r10, [reg_p1+136]   
    adc    r11, [reg_p1+144]  
    adc    r12, [reg_p1+152]  
    adc    r13, [reg_p1+160]   
    adc    r14, rcx
    mov    [reg_p2+32], r8
    mov    [reg_p2+40], r9  
    mov    [reg_p2+48], r10   
    mov    [reg_p2+56], r11  
    mov    [reg_p2+64], r12  
    mov    [reg_p2+72], r13  
    mov    [reg_p2+80], r14
	
    pop    rbx
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
.global fmt(rdc697_asm)
fmt(rdc697_asm):

  ret

# error "CONFIGURATION NOT SUPPORTED. TRY USE_MULX=TRUE"

  #endif

//***********************************************************************
//  697-bit multiprecision addition
//  Operation: c [reg_p3] = a [reg_p1] + b [reg_p2]
//*********************************************************************** 
.global fmt(mp_add697_asm)
fmt(mp_add697_asm):  
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
  mov    rcx, [reg_p1+80] 
  adc    r8, [reg_p2+40] 
  adc    r9, [reg_p2+48]
  adc    r10, [reg_p2+56] 
  adc    r11, [reg_p2+64]
  adc    rax, [reg_p2+72]
  adc    rcx, [reg_p2+80]
  mov    [reg_p3+40], r8
  mov    [reg_p3+48], r9
  mov    [reg_p3+56], r10
  mov    [reg_p3+64], r11
  mov    [reg_p3+72], rax
  mov    [reg_p3+80], rcx
  ret


//***********************************************************************
//  2x697-bit multiprecision subtraction/addition
//  Operation: c [x2] = a [x0] - b [x1]. If c < 0, add p697*2^704
//*********************************************************************** 
.global fmt(mp_subadd697x2_asm)
fmt(mp_subadd697x2_asm):
  push   r12
  push   r13 
  push   r14 
  push   r15
  push   rbx
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
  mov    rcx, [reg_p1+72] 
  sbb    r8, [reg_p2+40] 
  sbb    r9, [reg_p2+48] 
  sbb    r10, [reg_p2+56]
  sbb    r11, [reg_p2+64] 
  sbb    rcx, [reg_p2+72]
  mov    [reg_p3+40], r8
  mov    [reg_p3+48], r9
  mov    [reg_p3+56], r10
  mov    [reg_p3+64], r11
  mov    [reg_p3+72], rcx
  
  mov    r8, [reg_p1+80]
  mov    r9, [reg_p1+88] 
  mov    r10, [reg_p1+96]
  mov    r11, [reg_p1+104]
  mov    rcx, [reg_p1+112]
  sbb    r8, [reg_p2+80]
  sbb    r9, [reg_p2+88]
  sbb    r10, [reg_p2+96] 
  sbb    r11, [reg_p2+104] 
  sbb    rcx, [reg_p2+112]
  mov    [reg_p3+80], r8 
  mov    [reg_p3+88], r9
  mov    [reg_p3+96], r10
  mov    [reg_p3+104], r11
  mov    [reg_p3+112], rcx
  
  mov    r8, [reg_p1+120]
  mov    r9, [reg_p1+128]
  mov    r10, [reg_p1+136]
  mov    r11, [reg_p1+144]
  mov    rcx, [reg_p1+152]
  mov    r14, [reg_p1+160]
  mov    r15, [reg_p1+168]
  sbb    r8, [reg_p2+120] 
  sbb    r9, [reg_p2+128] 
  sbb    r10, [reg_p2+136] 
  sbb    r11, [reg_p2+144] 
  sbb    rcx, [reg_p2+152] 
  sbb    r14, [reg_p2+160] 
  sbb    r15, [reg_p2+168]
  mov    [reg_p3+160], r14
  mov    [reg_p3+168], r15
  sbb    rax, 0
  
  // Add p697 anded with the mask in rax 
  mov    r12, [rip+fmt(p697)]
  mov    r13, [rip+fmt(p697)+40]
  mov    r14, [rip+fmt(p697)+48]
  mov    r15, [rip+fmt(p697)+56]
  mov    rdi, [rip+fmt(p697)+64]
  mov    rsi, [rip+fmt(p697)+72]
  mov    rbx, [rip+fmt(p697)+80]
  and    r12, rax
  and    r13, rax
  and    r14, rax
  and    r15, rax
  and    rdi, rax
  and    rsi, rax
  and    rbx, rax
  mov    rax, [reg_p3+88]
  add    rax, r12
  mov    [reg_p3+88], rax
  mov    rax, [reg_p3+96]
  adc    rax, r12
  mov    [reg_p3+96], rax
  mov    rax, [reg_p3+104]
  adc    rax, r12
  mov    [reg_p3+104], rax
  mov    rax, [reg_p3+112]
  adc    rax, r12
  mov    [reg_p3+112], rax
  adc    r8, r12
  adc    r9, r13
  mov    [reg_p3+120], r8
  mov    [reg_p3+128], r9
  adc    r10, r14
  adc    r11, r15
  mov    r8, [reg_p3+160]
  mov    r9, [reg_p3+168]
  adc    rcx, rdi
  adc    r8, rsi
  adc    r9, rbx
  
  mov    [reg_p3+136], r10
  mov    [reg_p3+144], r11
  mov    [reg_p3+152], rcx
  mov    [reg_p3+160], r8
  mov    [reg_p3+168], r9
  pop    rbx
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret


//***********************************************************************
//  Double 2x697-bit multiprecision subtraction
//  Operation: c [reg_p3] = c [reg_p3] - a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global fmt(mp_dblsub697x2_asm)
fmt(mp_dblsub697x2_asm):
  push   r12
  push   r13
  push   r14
  push   r15
  
  mov    r8, [reg_p3]
  mov    r9, [reg_p3+8]
  mov    r10, [reg_p3+16]
  mov    r11, [reg_p3+24]
  mov    r12, [reg_p3+32]
  mov    r13, [reg_p3+40]
  mov    r14, [reg_p3+48]
  mov    r15, [reg_p3+56]
  sub    r8, [reg_p1]
  sbb    r9, [reg_p1+8] 
  sbb    r10, [reg_p1+16] 
  sbb    r11, [reg_p1+24] 
  sbb    r12, [reg_p1+32] 
  sbb    r13, [reg_p1+40] 
  sbb    r14, [reg_p1+48] 
  sbb    r15, [reg_p1+56]
  setc   al
  sub    r8, [reg_p2]
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24] 
  sbb    r12, [reg_p2+32] 
  sbb    r13, [reg_p2+40] 
  sbb    r14, [reg_p2+48] 
  sbb    r15, [reg_p2+56]
  setc   cl
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  mov    [reg_p3+32], r12
  mov    [reg_p3+40], r13
  mov    [reg_p3+48], r14
  mov    [reg_p3+56], r15
    
  mov    r8, [reg_p3+64]
  mov    r9, [reg_p3+72]
  mov    r10, [reg_p3+80]
  mov    r11, [reg_p3+88]
  mov    r12, [reg_p3+96]
  mov    r13, [reg_p3+104]
  mov    r14, [reg_p3+112]
  mov    r15, [reg_p3+120]
  bt     rax, 0 
  sbb    r8, [reg_p1+64] 
  sbb    r9, [reg_p1+72] 
  sbb    r10, [reg_p1+80] 
  sbb    r11, [reg_p1+88] 
  sbb    r12, [reg_p1+96] 
  sbb    r13, [reg_p1+104] 
  sbb    r14, [reg_p1+112] 
  sbb    r15, [reg_p1+120]
  setc   al 
  bt     rcx, 0  
  sbb    r8, [reg_p2+64] 
  sbb    r9, [reg_p2+72] 
  sbb    r10, [reg_p2+80] 
  sbb    r11, [reg_p2+88] 
  sbb    r12, [reg_p2+96] 
  sbb    r13, [reg_p2+104] 
  sbb    r14, [reg_p2+112] 
  sbb    r15, [reg_p2+120]
  setc   cl 
  mov    [reg_p3+64], r8
  mov    [reg_p3+72], r9
  mov    [reg_p3+80], r10
  mov    [reg_p3+88], r11
  mov    [reg_p3+96], r12
  mov    [reg_p3+104], r13
  mov    [reg_p3+112], r14
  mov    [reg_p3+120], r15
  
  mov    r8, [reg_p3+128]
  mov    r9, [reg_p3+136]
  mov    r10, [reg_p3+144]
  mov    r11, [reg_p3+152]
  mov    r12, [reg_p3+160]
  mov    r13, [reg_p3+168]
  bt     rax, 0 
  sbb    r8, [reg_p1+128] 
  sbb    r9, [reg_p1+136] 
  sbb    r10, [reg_p1+144] 
  sbb    r11, [reg_p1+152] 
  sbb    r12, [reg_p1+160] 
  sbb    r13, [reg_p1+168] 
  bt     rcx, 0 
  sbb    r8, [reg_p2+128] 
  sbb    r9, [reg_p2+136] 
  sbb    r10, [reg_p2+144] 
  sbb    r11, [reg_p2+152] 
  sbb    r12, [reg_p2+160] 
  sbb    r13, [reg_p2+168]
  mov    [reg_p3+128], r8
  mov    [reg_p3+136], r9
  mov    [reg_p3+144], r10
  mov    [reg_p3+152], r11
  mov    [reg_p3+160], r12
  mov    [reg_p3+168], r13
  
  pop    r15
  pop    r14
  pop    r13
  pop    r12
  ret