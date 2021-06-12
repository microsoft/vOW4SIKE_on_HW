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
// Abstract: field arithmetic in x64 assembly for P128 on Linux
//*******************************************************************************************  

.intel_syntax noprefix 

// Registers that are used for parameter passing:
#define reg_p1  rdi
#define reg_p2  rsi
#define reg_p3  rdx

.text
//***********************************************************************
//  Field addition
//  Operation: c [reg_p3] = a [reg_p1] + b [reg_p2]
//*********************************************************************** 
.global fpadd128_asm
fpadd128_asm:  
  xor    rax, rax
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  add    r8, [reg_p2] 
  adc    r9, [reg_p2+8]

  mov    rcx, [rip+p128x2]
  sub    r8, rcx
  mov    rcx, [rip+p128x2+8]
  sbb    r9, rcx
  sbb    rax, 0
  
  mov    rdi, [rip+p128x2]
  and    rdi, rax
  mov    rsi, [rip+p128x2+8]
  and    rsi, rax
  
  add    r8, rdi  
  adc    r9, rsi
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  ret


//***********************************************************************
//  Field subtraction
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global fpsub128_asm
fpsub128_asm:  
  xor    rax, rax
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    rax, 0
  
  mov    rdi, [rip+p128x2]
  and    rdi, rax
  mov    rsi, [rip+p128x2+8]
  and    rsi, rax
  
  add    r8, rdi  
  adc    r9, rsi
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  ret


///////////////////////////////////////////////////////////////// MACRO
.macro SUB128_PX  P0  
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 

  mov    rax, [rip+\P0]
  mov    rdi, [rip+\P0+8]
  add    r8, rax 
  adc    r9, rdi 
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9 
  .endm


//***********************************************************************
//  Multiprecision subtraction with correction with 2*p128
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 2*p128
//*********************************************************************** 
.global mp_sub128_p2_asm
mp_sub128_p2_asm:

  SUB128_PX  p128x2
  ret


//***********************************************************************
//  Multiprecision subtraction with correction with 4*p128
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2] + 4*p128
//*********************************************************************** 
.global mp_sub128_p4_asm
mp_sub128_p4_asm:

  SUB128_PX  p128x4
  ret


//***********************************************************************
//  Integer multiplication
//  Operation: c [reg_p3] = a [reg_p1] * b [reg_p2]
//  NOTE: a=c or b=c are not allowed
//***********************************************************************
.global mul128_asm
mul128_asm:
  xor    r10, r10
  mov    rcx, reg_p3
  
  mov    rax, [reg_p2]
  mov    r8, [reg_p1]
  mul    r8
  mov    [rcx], rax        // c0
  mov    r9, rdx
  
  mov    rax, [reg_p2+8]
  mul    r8
  add    r9, rax
  adc    r10, rdx
  
  xor    r11, r11
  mov    rax, [reg_p2]
  mov    r8, [reg_p1+8] 
  mul    r8
  add    r9, rax
  mov    [rcx+8], r9       // c1 
  adc    r10, rdx
  adc    r11, 0
  
  mov    rax, [reg_p2+8]
  mul    r8
  add    r10, rax          
  adc    r11, rdx         
  mov    [rcx+16], r10      // c2 
  mov    [rcx+24], r11      // c3 
  ret

  
//***********************************************************************
//  Montgomery reduction
//  Operation: c [reg_p2] = a [reg_p1]
//  NOTE: a=c is not allowed
//*********************************************************************** 
.global rdc128_asm
rdc128_asm: 
  mov    rax, [rip+p128pp]
  mov    r8, [reg_p1]
  mul    r8
  mov    [reg_p2], rax     // c0
  mov    r9, rdx
  
  mov    rax, [rip+p128pp+8]
  mul    r8
  add    r9, rax
  
  mov    rax, [rip+p128pp]
  mov    r8, [reg_p1+8]
  mul    r8
  add    r9, rax
  mov    [reg_p2+8], r9    // c1
    
  // mc = (ma + mc x p128)/2^128
  xor    r10, r10  
  mov    rax, [rip+p128]
  mov    r8, [reg_p2]
  mul    r8
  mov    rcx, rax          // mc0
  mov    r9, rdx
  
  mov    rax, [rip+p128+8]
  mul    r8
  add    r9, rax
  adc    r10, rdx
  
  xor    r11, r11
  mov    rax, [rip+p128] 
  mov    r8, [reg_p2+8]
  mul    r8
  add    r9, rax           // mc1 
  adc    r10, rdx
  adc    r11, 0
  
  mov    rax, [rip+p128+8]
  mul    r8
  add    r10, rax          // mc2          
  adc    r11, rdx          // mc3

  add    rcx, [reg_p1]
  adc    r9, [reg_p1+8]
  adc    r10, [reg_p1+16]
  adc    r11, [reg_p1+24]
  mov    [reg_p2], r10
  mov    [reg_p2+8], r11
  ret


//***********************************************************************
//  128-bit multiprecision addition
//  Operation: c [reg_p3] = a [reg_p1] + b [reg_p2]
//*********************************************************************** 
.global mp_add128_asm
mp_add128_asm: 
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  add    r8, [reg_p2] 
  adc    r9, [reg_p2+8]
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  ret


//***************************************************************************
//  2x128-bit multiprecision subtraction/addition
//  Operation: c [reg_p3] = a [reg_p1] - b [reg_p2]. If c < 0, add p128*2^128
//*************************************************************************** 
.global mp_subadd128x2_asm
mp_subadd128x2_asm:
  xor    rax, rax
  mov    r8, [reg_p1]
  mov    r9, [reg_p1+8]
  mov    r10, [reg_p1+16]
  mov    r11, [reg_p1+24]
  sub    r8, [reg_p2] 
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24]
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  sbb    rax, 0
  
  // Add p128 anded with the mask in rax 
  mov    r8, [rip+p128]
  mov    r9, [rip+p128+8]
  and    r8, rax
  and    r9, rax
  add    r10, r8
  adc    r11, r9  
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  ret


//***********************************************************************
//  Double 2x128-bit multiprecision subtraction
//  Operation: c [reg_p3] = c [reg_p3] - a [reg_p1] - b [reg_p2]
//*********************************************************************** 
.global mp_dblsub128x2_asm
mp_dblsub128x2_asm:
  mov    r8, [reg_p3]
  mov    r9, [reg_p3+8]
  mov    r10, [reg_p3+16]
  mov    r11, [reg_p3+24]
  sub    r8, [reg_p1]
  sbb    r9, [reg_p1+8] 
  sbb    r10, [reg_p1+16] 
  sbb    r11, [reg_p1+24]
  sub    r8, [reg_p2]
  sbb    r9, [reg_p2+8] 
  sbb    r10, [reg_p2+16] 
  sbb    r11, [reg_p2+24]
  mov    [reg_p3], r8
  mov    [reg_p3+8], r9
  mov    [reg_p3+16], r10
  mov    [reg_p3+24], r11
  ret