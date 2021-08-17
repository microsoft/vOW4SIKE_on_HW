# vOW4SIKE on Hardware - Parallel Collision Search for the Cryptanalysis of SIKE using hardware/software co-design

This repository hosts a proof-of-concept, hardware/software co-design of the 
van Oorschot-Wiener (vOW) algorithm on [SIKE](https://sike.org/) [1] that is based on 
the RISC-V platform called [Murax SoC](https://github.com/SpinalHDL/VexRiscv/blob/master/README.md#murax-soc).
It includes especially-tailored, ASIC-friendly hardware accelerators 
for the large-degree isogeny computation, which is the single most-critical operation in the cryptanalysis of SIKE.

This library, which is released for experimentation purposes, is used to estimate the classical security of SIKE parameter sets
in [2], and can be used as basis for a real-world, large-scale cryptanalytic effort on SIKE.
The library also includes the implementation of new, more efficient SIKE parameter sets, and Python scripts for the security estimation of SIKE
relative to AES and SHA-3.

* [File Organization](#file-organization) 

* [Install Pre-requisites](#install-pre-requisites) 

* [Tools Versions](#tools-versions) 

* [Testing on FPGAs](#testing-on-fpgas) 
 
* [Contributors](#contributors) 
 
* [References](#references) 

- - -
## File Organization

- `platforms/AC701/` contains hardware development files targeting the Artix-7 AC701 XC7A200TFBG676 FPGA.
 
- `platforms/Murax/` contains the scala source code for generating the Murax SoC.

- `platforms/rtl` contains the APB bridge modules developed for the communication between the software and hardware.

- `Python_script` contains the Python3 script for the security estimation of SIKE relative to AES and SHA-3.

- `SIKE_sw` contains the software implementation of SIKE, including the new parameter sets SIKEp377, SIKEp546 and SIKEp697.

- `SIKE_vOW_hw-sw/hardware` contains the hardware accelerators source code.

- `SIKE_vOW_hw-sw/murax` contains the Murax library files.

- `SIKE_vOW_hw-sw/ref_c` contains the software implementation of vOW on SIKE, which is based on [3] and the [vOW4SIKE library](https://github.com/microsoft/vOW4SIKE).
  This implementation is used by the hardware/software co-design in `SIKE_vOW_hw-sw/ref_c_riscv`, but can also be run standalone in software.

- `SIKE_vOW_hw-sw/ref_c_riscv` contains the hardware/software co-design of vOW on SIKE. 
  It contains the software libraries for calling the hardware accelerators and RISC-V testing files.

- `LICENSE` MIT license covering all the implementations, except for the files that are labeled as created by third parties.

- `README.md` this readme file.

- - -
## Install Pre-requisites

The information below is collected from the README.md files from

- https://github.com/SpinalHDL/openocd_riscv
- https://github.com/SpinalHDL/VexRiscv and 
- https://github.com/SpinalHDL/SpinalHDL

The following tools need to be installed before running the design:

On Ubuntu 14 :

Install JAVA JDK 7 or 8

```sh
sudo apt-get install openjdk-8-jdk
```

Install SBT

```sh
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
sudo apt-get update
sudo apt-get install sbt
```

Compile the latest SpinalHDL

```sh
rm -rf SpinalHDL
git clone https://github.com/SpinalHDL/SpinalHDL.git 
```
 
Download VexRiscv hardware code  

```sh
git clone https://github.com/SpinalHDL/VexRiscv.git 
```

Install RISC-V GCC toolchain

```sh

### Get pre-compiled GCC
wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6.tar.gz
tar -xzvf riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6.tar.gz
sudo mv riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6 /opt/riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6
sudo mv /opt/riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6 /opt/riscv
echo 'export PATH=/opt/riscv/bin:$PATH' >> ~/.bashrc
```

Download and build openocd

```sh
### Get OpenOCD version from SpinalHDL
git clone https://github.com/SpinalHDL/openocd_riscv.git
### Install OpenOCD dependencies:
sudo apt-get install libtool automake libusb-1.0.0-dev texinfo libusb-dev libyaml-dev pkg-config
./bootstrap
./configure --enable-ftdi --enable-dummy
make
```  
 
- - -
## Tools Versions

Here are the tool versions that were used for testing (we recommend that users use the same versions).

- SageMath (sage) 6.3 and 7.4

- Python (python) 2.7

- Icarus Verilog (iverilog) 0.9.7

- Vivado 2018.3

- Quartus (quartus) 16.1
 
- gcc version 5.4.0

- others: newest versions

- - -
## Testing on FPGAs

Hardware pre-requisites: 

- Artix-7 AC701 XC7A200TFBG676 FPGA
- HW-FMC-105 DBUG card for extending GPIO pins on the FPGA 
- USB-JTAG connection for programming the FPGA
- USB-serial connection for IO of the Murax SoC
- USB-JTAG connection for programming and debugging the software on the Murax SoC

Note: the designs were tested on an Xilinx Artix-7 AC701 FPGA. 
The design is not FPGA specific and, therefore, should run on any FPGA with enough logic resources and memory.  

The following steps show how to run the whole software/hardware co-design on the FPGA 
(compile the code, start openocd, start serial interface, load the binary to the Murax SoC through jtagd, check outputs, etc)

### Step 1: Generate FPGA bitstream and program the FPGA
 
Choose **TARGET**

- `Murax` plain Murax SoC 
- `MuraxControllerMontgomeryMultiplier` Murax SoC integrated with SIKE isogeny accelerator 
 
Generate the bitstream and program the FPGA:

```sh 
cd platforms/AC701/
make TARGET=$(TARGET) clean 
make TARGET=$(TARGET) program 
```

### Step 2: Open serial port connection to the Murax SoC on FPGA

Start a new terminal window

```sh
# Assuming /dev/ttyUSB5 is the serial port
# If $USER is not in "dialout" group, need to use add sudo before minicom
minicom --baudrate 9600 --device=/dev/ttyUSB0
``` 

### Step 3: Open jtag connection to Murax on FPGA

Start a new terminal window

```sh 
cd openocd_riscv
sudo src/openocd -f tcl/interface/ftdi/c232hm.cfg -c "set MURAX_CPU0_YAML ../SIKE_HW_cryptanalysis/platforms/AC701/cpu0.yaml" -f tcl/target/murax.cfg
```

### Step 4: Connect GDB to load binary onto the Murax SoC on FPGA through Murax jtag interface

Start a new terminal window

Now, compile the software code for the required **TARGET** and load it to the Murax SoC
(here, the **TARGET** must fit to the hardware platform from Step 1):

```sh
cd SIKE_vOW_hw-sw/ref_c_riscv/SIKE_cryptanalysis
make TARGET=$(TARGET) PROJ=test_vOW_SIKE clean
make TARGET=$(TARGET) PROJ=test_vOW_SIKE run  
```

### Step 5: Verify outputs

The outputs are displayed in the minicom window (Step 2).

- - -
## Contributors

- Wen Wang 
 

## References 

[1] David Jao, Reza Azarderakhsh, Matthew Campagna, Craig Costello, Luca De Feo, Basil Hess, Aaron Hutchinson, Amir Jalali, Koray Karabina, Brian Koziel, Brian LaMacchia, Patrick Longa, Michael Naehrig, Geovandro Pereira, Joost Renes, Vladimir Soukharev, David Urbanik:
SIKE: Supersingular Isogeny Key Encapsulation, [`https://sike.org`](https://sike.org).

[2] Patrick Longa, Wen Wang, Jakub Szefer: The Cost to Break SIKE: A Comparative Hardware-Based Analysis with AES and SHA-3, CRYPTO 2021,
[`https://eprint.iacr.org/2020/1457`](https://eprint.iacr.org/2020/1457).

[3] Craig Costello, Patrick Longa, Michael Naehrig, Joost Renes, Fernando Virdia: Improved Classical Cryptanalysis of SIKE in Practice, PKC 2020,
[`https://eprint.iacr.org/2019/298`](https://eprint.iacr.org/2019/298).


## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
