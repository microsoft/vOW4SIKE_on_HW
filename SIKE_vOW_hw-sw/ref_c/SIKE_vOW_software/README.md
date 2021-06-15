# vOW4SIKE: software implementation

This folder contains the software implementation of the van Oorschot-Wiener (vOW) algorithm on SIKE
that is used by the HW/SW co-design project. 

The instructions for the setup of the HW/SW co-design can be found in the main `README.md` file.

This implementation can also be run standalone in software.
The instructions to do so are given below.    

## Setup and compilation instructions on Linux

#### xxHash

By default, the xxHash non-cryptographic hash function is used for the XOF for performance reasons.

To use AES instead, comment out the define for USE_XXHASH_XOF in `\src\prng.h`, and uncomment the define for USE_AES_XOF.

#### Linux

To compile and run the assembly-optimized code on Linux, use the following commands.
The code assumes a 64-bit architecture is being targeted.

```bash
make tests_vow_sikeXXX
./test_vOW_SIKE_XXX -s -h
```

Where XXX is any option in {128, 377, 434}. 

The option -h displays the options for the command.
The option -s allows to run one single function version and collect some statistics.
If this option is not used, the attack is run for multiple function versions but restricted to isogenies with artificially shortened degrees
(e.g., by default e = 20 for P377 and P434. See `\SIKE_vOW_hw-sw\ref_c\SIKE_vOW_software\src\sike_vow_constants.c`). 
Expect a short execution for P128, but not for the larger primes. 

It is also possible to run some tests to check the arithmetic and computation of SIKE.

To test the field arithmetic, use the following commands: 

```bash
make clean
make tests
./arith_tests-pXXX
```

To run and test SIKE, use the following commands: 

```bash
make clean
make tests_sike
./sikeXXX/test_SIKE
```
