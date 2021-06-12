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

make tests_vow_sike
./test_vOW_SIKE_128 -h
./test_vOW_SIKE_377 -h
./test_vOW_SIKE_434 -h