# Software implementation of SIKE

This library contains efficient C implementations of the CCA-secure key encapsulation mechanism SIKE [2], 
which is a scheme that is conjectured to be secure against classical and quantum computer attacks.
The software is based on the [SIDH library](https://github.com/microsoft/PQCrypto-SIDH), version 3.4,
but additionally contains the new paremeter sets proposed in [1]. 

This library includes the following KEM schemes:

* SIKEp377: matching the post-quantum security of AES128 (NEW, level 1).
* SIKEp434: matching the post-quantum security of AES128 (level 1).
* SIKEp503: matching the post-quantum security of SHA3-256 (level 2).
* SIKEp546: matching the post-quantum security of AES192 (NEW, level 3).
* SIKEp610: matching the post-quantum security of AES192 (level 3).
* SIKEp697: matching the post-quantum security of AES256 (NEW, level 5).
* SIKEp751: matching the post-quantum security of AES256 (level 5).

## Contents

In the remainder, pXXX is one of {p377,p434,p503,p546,p610,p697,p751}.

* [`src folder`](src/): C and header files. Public APIs can be found in src/PXXX/PXXX_api.h.
* Optimized x64 implementation for pXXX (src/PXXX/AMD64/): optimized implementation of the field arithmetic over the prime pXXX for x64 platforms. 
* Generic implementation for pXXX (src/PXXX/generic/): implementation of the field arithmetic over the prime pXXX in portable C.
* [`random folder`](src/random/): randombytes function using the system random number generator.
* [`sha3 folder`](src/sha3/): SHAKE256 implementation.  
* [`Test folder`](tests/): test files.   
* [`Visual Studio folder`](Visual%20Studio/): Visual Studio 2015 files for compilation in Windows.
* [`Makefile`](Makefile): Makefile for compilation using the GNU GCC or clang compilers on Linux. 
* [`Readme`](README.md): this readme file.

## Instructions for Linux

By executing:

```sh
$ make
```

the library is compiled by default for x64 using clang, optimization level `FAST` that uses assembly-optimized arithmetic
(this option requires CPU support for the instructions MULX and ADX).

Other options for x64:

```sh
$ make CC=[gcc/clang] OPT_LEVEL=[FAST/GENERIC]
```

The use of `OPT_LEVEL=GENERIC` disables the use of assembly-optimized arithmetic.

To run the different tests and benchmarking results, execute:

```sh
$ ./arith_tests-pXXX
$ ./sikeXXX/test_SIKE
```

## References 

[1] David Jao, Reza Azarderakhsh, Matthew Campagna, Craig Costello, Luca De Feo, Basil Hess, Aaron Hutchinson, Amir Jalali, Koray Karabina, Brian Koziel, Brian LaMacchia, Patrick Longa, Michael Naehrig, Geovandro Pereira, Joost Renes, Vladimir Soukharev, David Urbanik:
SIKE: Supersingular Isogeny Key Encapsulation, [`https://sike.org`](https://sike.org).

[2] Patrick Longa, Wen Wang, Jakub Szefer: The Cost to Break SIKE: A Comparative Hardware-Based Analysis with AES and SHA-3, CRYPTO 2021,
[`https://eprint.iacr.org/2020/1457`](https://eprint.iacr.org/2020/1457).
