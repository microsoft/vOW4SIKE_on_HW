#####################################################################################################################
# Python3 script to calculate security estimates using a budget-based cost model on ASICs 
# Targeted primitives: SIKE, AES and SHA-3
# Technology used by the hardware implementations used in the model: NanGate 45nm open-cell library
#
# The script produces all the figures and security estimates included in the paper:
#      "The Cost to Break SIKE: A Comparative Hardware-Based Analysis with AES and SHA-3",
#      Patrick Longa, Wen Wang, Jakub Szefer. CRYPTO 2021
#      https://eprint.iacr.org/2020/1457
#####################################################################################################################

import math
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator

# Assumptions and constants
NumberTransPerGate = 4           # Number of transistors per 2-NAND CMOS Gate Equivalent (GE)
SecondsPerYear = 3600*24*365     # Seconds in a year
MoneyOptions = [1e6, 10e6, 100e6, 1000e6, 10000e6, 100000e6, 1000000e6]  # One million, ten million, hundred million, one billion, ten billion, hundred billion, one trillion (in US$)
titlefigure = "on"
dividepricebyfactor = "on"       # Reduction factor applied to the transistor and memory release prices. 
reductionpricefactor = 7.40      # This factor is obtained using the estimated transistor cost at production for year 2020 (reference: Khan and Mann (2020)) 
                                 # In contrast to release prices, the adjusted prices are expected to match more closely production costs in bulk.

############################################################################################
#### Historical prices of memory and transistors/gates (see paper for references)

# Hard drive disk (HDD) cost US$, years 2000-2020
CostHDD = [125.00, 259.00, 146.00, 89.99, 97.50, 130.00, 69.99, 99.99, 99.99, 69.99, 89.99, 54.99, 54.99, 54.99, 104.99, 84.99, 221.63, 99.99, 93.49, 149.99, 129.99]
# Hard drive disk (HDD) bytes, years 2000-2020
BytesHDD = [3.07e10, 1e11, 1.2e11, 1.2e11, 1.6e11, 3.2e11, 3.2e11, 5.0e11, 1.0e12, 1.0e12, 2.0e12, 1.5e12, 1.5e12, 1.5e12, 3.0e12, 3.0e12, 8.0e12, 4.0e12, 4.0e12, 8.0e12, 8.0e12]

# Dynamic random-access memory (RAM) cost US$, years 2000-2020
CostDRAM = [89.00, 18.89, 34.19, 39.00, 39.00, 39.00, 148.99, 49.95, 39.99, 39.99, 39.99, 41.99, 29.99, 29.99, 29.99, 29.99, 44.99, 44.99, 44.99, 44.99, 44.99]
# Dynamic random-access memory (RAM) bytes, years 2000-2020
BytesDRAM = [1.31e8, 1.31e8, 2.62e8, 5.24e8, 5.24e8, 5.24e8, 20.97e8, 20.97e8, 41.94e8, 41.94e8, 41.94e8, 83.89e8, 83.89e8, 83.89e8, 83.89e8, 83.89e8, 167.77e8, 167.77e8, 167.77e8, 167.77e8, 167.77e8]

# Solid state drive (SSD) cost US$, years 2000-2020
CostSSD = [None, None, None, None, None, None, None, None, None, None, None, None, None, 159.99, 179.99, 59.99, 194.99, 194.99, 49.99, 75.99, 75.99]
# Solid state drive (SSD) bytes, years 2000-2020
BytesSSD = [None, None, None, None, None, None, None, None, None, None, None, None, None, 2.56e11, 4.80e11, 2.40e11, 9.60e11, 9.60e11, 4.80e11, 9.60e11, 9.60e11]

# MPU cost US$ (Intel), years 2000-2020
CostMPU_Intel = [112.0, 64.0, 33.0, 33.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 70.0, 42.0, 117.0, 122.0, 42.0, 42.0, None, None, None, None, None ]
# MPU cost US$ (AMD), years 2000-2020
CostMPU_AMD = [None, None, None, None, None, None, None, None, None, None, None, 79.0, 71.0, 71.0, 101.0, 79.0, 58.0, 51.0, 51.0, 51.0, 60.0]
# Intel and AMD MPU costs US$, years 2000-2020 (corresponding to the lowest cost per transistor per year)
CostMPU = [112.0, 64.0, 33.0, 33.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 70.0, 79.0, 71.0, 71.0, 42.0, 42.0, 58.0, 51.0, 51.0, 51.0, 60.0]

# MPU transistors (Intel), years 2000-2020
TransMPU_Intel = [28.1e6, 28.1e6, 55e6, 55e6, 125e6, 125e6, 125e6, 125e6, 125e6, 125e6, 382e6, 624e6, 1400e6, 1400e6, 1400e6, 1400e6, None, None, None, None, None]
# MPU transistors (AMD), years 2000-2020
TransMPU_AMD = [None, None, None, None, None, None, None, None, None, None, None, 1178e6, 1303e6, 1303e6, 2410e6, 2410e6, 3100e6, 3100e6, 3100e6, 3100e6, 4940e6]
# Intel and AMD MPU transistors, years 2000-2020 (corresponding to lowest cost per transistor per year) 
TransMPU = [28.1e6, 28.1e6, 55e6, 55e6, 125e6, 125e6, 125e6, 125e6, 125e6, 125e6, 382e6, 1178e6, 1303e6, 1303e6, 1400e6, 1400e6, 3100e6, 3100e6, 3100e6, 3100e6, 4940e6]

DollarsPerByte_HDD = []
BytesPerDollar_HDD = []
DollarsPerByte_DRAM = []
BytesPerDollar_DRAM = []
DollarsPerByte_SSD = []
BytesPerDollar_SSD = []
DollarsPerTrans_MPU = []
TransPerDollar_MPU = []
DollarsPerGate_MPU = []
GatesPerDollar_MPU = []
BytesPerGate = []
for i in range(0,21):
    DollarsPerByte_HDD.append(CostHDD[i]/BytesHDD[i])
    BytesPerDollar_HDD.append(1/DollarsPerByte_HDD[i])
    DollarsPerByte_DRAM.append(CostDRAM[i]/BytesDRAM[i])
    BytesPerDollar_DRAM.append(1/DollarsPerByte_DRAM[i])
    if CostSSD[i] == None:
        DollarsPerByte_SSD.append(None)
        BytesPerDollar_SSD.append(None)
    else:
        DollarsPerByte_SSD.append(CostSSD[i]/BytesSSD[i])
        BytesPerDollar_SSD.append(1/DollarsPerByte_SSD[i])
    DollarsPerTrans_MPU.append(CostMPU[i]/TransMPU[i])
    TransPerDollar_MPU.append(TransMPU[i]/CostMPU[i])
    DollarsPerGate_MPU.append((CostMPU[i]*NumberTransPerGate)/TransMPU[i])
    GatesPerDollar_MPU.append(1/DollarsPerGate_MPU[i])
    if dividepricebyfactor == 'on': 
        BytesPerDollar_HDD[i] *= reductionpricefactor
        GatesPerDollar_MPU[i] *= reductionpricefactor
        BytesPerDollar_DRAM[i] *= reductionpricefactor
        if BytesPerDollar_SSD[i] != None: BytesPerDollar_SSD[i] *= reductionpricefactor
    BytesPerGate.append(BytesPerDollar_HDD[i]/GatesPerDollar_MPU[i])
        
# Linley Group report (ITRS 2014) with costs of transistors, years 2002-2014 (every two years)
GatesPerDollar_Linley = [None, None, 2.6e6/NumberTransPerGate, None, 4.4e6/NumberTransPerGate, None, 7.3e6/NumberTransPerGate, None, 11.2e6/NumberTransPerGate, 
                         None, 16.0e6/NumberTransPerGate, None, 20.0e6/NumberTransPerGate, None, 20.0e6/NumberTransPerGate, 19.0e6/NumberTransPerGate, None, None, None, None, None]
        
# ITRS 2007 forecast for costs of transistors, years 2002-2014 (every two years)
GatesPerDollar_ITRS = [None, 1/(9.7e-7*NumberTransPerGate), 1/(6.9e-7*NumberTransPerGate), 1/(4.9e-7*NumberTransPerGate), 1/(3.4e-7*NumberTransPerGate), 
                         1/(2.44e-7*NumberTransPerGate), 1/(1.72e-7*NumberTransPerGate), 1/(1.22e-7*NumberTransPerGate), 1/(8.6e-8*NumberTransPerGate), 
                         1/(6.1e-8*NumberTransPerGate), 1/(4.3e-8*NumberTransPerGate), 1/(3.0e-8*NumberTransPerGate), 1/(2.2e-8*NumberTransPerGate), 
                         1/(1.5e-8*NumberTransPerGate), 1/(1.1e-8*NumberTransPerGate), 1/(7.6e-9*NumberTransPerGate), 1/(5.4e-9*NumberTransPerGate), 
                         1/(3.8e-9*NumberTransPerGate), 1/(2.7e-9*NumberTransPerGate), 1/(1.9e-9*NumberTransPerGate), 1/(1.3e-9*NumberTransPerGate)]
    
print (BytesPerDollar_HDD)
print (BytesPerDollar_DRAM)
print (BytesPerDollar_SSD)
print (TransPerDollar_MPU)
print (GatesPerDollar_MPU)
print (BytesPerGate)

#########################################################################################################
#### "Optimistic" projections for prices of memory and transistors/gates, years 2025-2040, every 5 years.
#### Based on a constant rate in cost reduction derived from data between years 2015 and 2020 
#### For memory (HDD): reduction factor = BytesPerDollar_SSD[20] / BytesPerDollar_SSD[15]  
#### For gates  (MPU): reduction factor = GatesPerDollar_MPU[20] / GatesPerDollar_MPU[15]

memrate = BytesPerDollar_SSD[20] / BytesPerDollar_SSD[15]
transrate = GatesPerDollar_MPU[20] / GatesPerDollar_MPU[15]

ProjBytesPerDollar_HDD = [BytesPerDollar_HDD[0], BytesPerDollar_HDD[5], BytesPerDollar_HDD[10], BytesPerDollar_HDD[15], BytesPerDollar_HDD[20],
                          BytesPerDollar_HDD[20]*memrate, BytesPerDollar_HDD[20]*memrate**2, BytesPerDollar_HDD[20]*memrate**3, BytesPerDollar_HDD[20]*memrate**4]

ProjGatesPerDollar_MPU = [GatesPerDollar_MPU[0], GatesPerDollar_MPU[5], GatesPerDollar_MPU[10], GatesPerDollar_MPU[15], GatesPerDollar_MPU[20],
                          GatesPerDollar_MPU[20]*transrate, GatesPerDollar_MPU[20]*transrate**2, GatesPerDollar_MPU[20]*transrate**3, GatesPerDollar_MPU[20]*transrate**4]
                  
############################################################################################
#### AES security estimator

def AES_estimator(version, AESgates, AEStime, YearIndex, Money, BytesPerDollar_HDD, GatesPerDollar_MPU):
    N=2**version                                # Number of AES operations (search space)
    AESperYear=SecondsPerYear/AEStime           # Number of AES operations per year per key-search engine
    bytesIO=version/8                           # Number of bytes to represent input and outputs

    p=Money*GatesPerDollar_MPU[YearIndex]/AESgates   # Number of key-search engines I can buy
    w=p*(2*bytesIO + bytesIO)                        # Required storage: two input buffers and one output buffer per engine
    
    if w*GatesPerDollar_MPU[YearIndex] > p*BytesPerDollar_HDD[YearIndex]*AESgates/8:  # Check that cost of memory is relatively small 
        return 'failed', 0, 0, 0
    LogMemBytes = math.log2(w)
    LogEngUnits = math.log2(p)
    LogYears = math.log2(N/(p * AESperYear))

    return 'passed', LogYears, LogMemBytes, LogEngUnits

############################################################################################
#### AES128

version = 128               # AES128  
AESgates = 11587            # Number of GEs occupied by Ueno et al.'s AES128 implementation
node = 45                   # 45nm
NISTgates=2**15             # AES gate complexity according to NIST

if version == 128:
    AEStime = (13.97e-9 * 10/11)     # InvThroughput of AES encryption implementation by Ueno et al. on 45nm
elif version == 192:
    AEStime = (17.16e-9 * 12/13)  
elif version == 256:
    AEStime = (19.35e-9 * 14/15)  

print ("\nAES" +repr(version))
print ("-------------------")
print ("\nSerial key-search (NIST):")
N=2**version
p=1              # Processor use
print ("N * AES in gates: 2 ^", math.log2((N * NISTgates) * p))

print ("\nParallel key-search, 45nm, based on Ueno et al.'s implementation:")
print ("Ueno et al. 2020 using 45nm: throughput of 13.97 * 10/11 = 12.7nsec/AES128 encryption, area of 11,587 GE")
print ("N * AES in seconds: 2 ^", math.log2(N * AEStime), "\n")

YearsAES128 = [[None for i in range(21)] for j in range(7)]
MemBytesAES128 = [[None for i in range(21)] for j in range(7)]
EngUnitsAES128 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("AES128: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        if CostMPU[YearIndex] != None:
            test, LogYears, LogMemBytes, LogEngUnits = AES_estimator(version, AESgates, AEStime, YearIndex, MoneyOptions[k], BytesPerDollar_HDD, GatesPerDollar_MPU)
            if test == 'passed':
                YearsAES128[k][YearIndex] = LogYears
                MemBytesAES128[k][YearIndex] = LogMemBytes
                EngUnitsAES128[k][YearIndex] = LogEngUnits
            else:
                print ("ERROR: memory is not negligible")
    print ("Log(years):", YearsAES128[k]); print ("Log(memory bytes):", MemBytesAES128[k]); print ("Log(engine units):", EngUnitsAES128[k], "\n")

ProjYearsAES128 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesAES128 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsAES128 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):
    print ("AES128 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        if CostMPU[YearIndex] != None:
            test, LogYears, LogMemBytes, LogEngUnits = AES_estimator(version, AESgates, AEStime, YearIndex, MoneyOptions[k], ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
            if test == 'passed':
                ProjYearsAES128[k][YearIndex] = LogYears
                ProjMemBytesAES128[k][YearIndex] = LogMemBytes
                ProjEngUnitsAES128[k][YearIndex] = LogEngUnits
            else:
                print ("ERROR: memory is not negligible")
    print ("Log(years):", ProjYearsAES128[k]); print ("Log(memory bytes):", ProjMemBytesAES128[k]); print ("Log(engine units):", ProjEngUnitsAES128[k], "\n")

############################################################################################
#### AES192

version = 192               # AES192 
AESgates = 13319            # Number of GEs occupied by Ueno et al.'s AES192 implementation
node = 45                   # 45nm
NISTgates=2**15             # AES gate complexity according to NIST

if version == 128:
    AEStime = (13.97e-9 * 10/11)     
elif version == 192:
    AEStime = (17.16e-9 * 12/13)     # InvThroughput of AES encryption implementation by Ueno et al. on 45nm
elif version == 256:
    AEStime = (19.35e-9 * 14/15)

print ("\nAES" +repr(version))
print ("-------------------")
print ("\nSerial key-search (NIST):")
N=2**version
p=1              # Processor use
print ("N * AES in gates: 2 ^", math.log2((N * NISTgates) * p))

print ("\nParallel key-search, 45nm, based on Ueno et al.'s implementation:")
print ("Ueno et al. 2020 using 45nm: throughput of 17.16 * 12/13 = 15.84nsec/AES192 encryption, area of 13,319 GE")
print ("N * AES in seconds: 2 ^", math.log2(N * AEStime), "\n")

YearsAES192 = [[None for i in range(21)] for j in range(7)]
MemBytesAES192 = [[None for i in range(21)] for j in range(7)]
EngUnitsAES192 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("AES192: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        if CostMPU[YearIndex] != None:
            test, LogYears, LogMemBytes, LogEngUnits = AES_estimator(version, AESgates, AEStime, YearIndex, MoneyOptions[k], BytesPerDollar_HDD, GatesPerDollar_MPU)
            if test == 'passed':
                YearsAES192[k][YearIndex] = LogYears
                MemBytesAES192[k][YearIndex] = LogMemBytes
                EngUnitsAES192[k][YearIndex] = LogEngUnits
            else:
                print ("ERROR: memory is not negligible")
    print ("Log(years):", YearsAES192[k]); print ("Log(memory bytes):", MemBytesAES192[k]); print ("Log(engine units):", EngUnitsAES192[k], "\n")

ProjYearsAES192 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesAES192 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsAES192 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):
    print ("AES192 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        if CostMPU[YearIndex] != None:
            test, LogYears, LogMemBytes, LogEngUnits = AES_estimator(version, AESgates, AEStime, YearIndex, MoneyOptions[k], ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
            if test == 'passed':
                ProjYearsAES192[k][YearIndex] = LogYears
                ProjMemBytesAES192[k][YearIndex] = LogMemBytes
                ProjEngUnitsAES192[k][YearIndex] = LogEngUnits
            else:
                print ("ERROR: memory is not negligible")
    print ("Log(years):", ProjYearsAES192[k]); print ("Log(memory bytes):", ProjMemBytesAES192[k]); print ("Log(engine units):", ProjEngUnitsAES192[k], "\n")

############################################################################################
#### AES256

version = 256               # AES256 
AESgates = 13974            # Number of GEs occupied by Ueno et al.'s AES256 implementation
node = 45                   # 45nm
NISTgates=2**16             # AES gate complexity according to NIST

if version == 128:
    AEStime = (13.97e-9 * 10/11)     
elif version == 192:
    AEStime = (17.16e-9 * 12/13)  
elif version == 256:
    AEStime = (19.35e-9 * 14/15)     # InvThroughput of AES encryption implementation by Ueno et al. on 45nm

print ("\nAES" +repr(version))
print ("-------------------")
print ("\nSerial key-search (NIST):")
N=2**version
p=1              # Processor use
print ("N * AES in gates: 2 ^", math.log2((N * NISTgates) * p))

print ("\nParallel key-search, 45nm, based on Ueno et al.'s implementation:")
print ("Ueno et al. 2020 using 45nm: throughput of 19.35 * 14/15 = 18.06nsec/AES256 encryption, area of 13,974 GE")
print ("N * AES in seconds: 2 ^", math.log2(N * AEStime), "\n")

YearsAES256 = [[None for i in range(21)] for j in range(7)]
MemBytesAES256 = [[None for i in range(21)] for j in range(7)]
EngUnitsAES256 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("AES256: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        if CostMPU[YearIndex] != None:
            test, LogYears, LogMemBytes, LogEngUnits = AES_estimator(version, AESgates, AEStime, YearIndex, MoneyOptions[k], BytesPerDollar_HDD, GatesPerDollar_MPU)
            if test == 'passed':
                YearsAES256[k][YearIndex] = LogYears
                MemBytesAES256[k][YearIndex] = LogMemBytes
                EngUnitsAES256[k][YearIndex] = LogEngUnits
            else:
                print ("ERROR: memory is not negligible")
    print ("Log(years):", YearsAES256[k]); print ("Log(memory bytes):", MemBytesAES256[k]); print ("Log(engine units):", EngUnitsAES256[k], "\n")

ProjYearsAES256 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesAES256 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsAES256 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):
    print ("AES256 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        if CostMPU[YearIndex] != None:
            test, LogYears, LogMemBytes, LogEngUnits = AES_estimator(version, AESgates, AEStime, YearIndex, MoneyOptions[k], ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
            if test == 'passed':
                ProjYearsAES256[k][YearIndex] = LogYears
                ProjMemBytesAES256[k][YearIndex] = LogMemBytes
                ProjEngUnitsAES256[k][YearIndex] = LogEngUnits
            else:
                print ("ERROR: memory is not negligible")
    print ("Log(years):", ProjYearsAES256[k]); print ("Log(memory bytes):", ProjMemBytesAES256[k]); print ("Log(engine units):", ProjEngUnitsAES256[k], "\n")

############################################################################################
#### SHA-3 security estimator

def SHA3_estimator(version, SHA3gates, SHA3time, YearIndex, Money, p, top_zero_bits, BytesPerDollar_HDD, GatesPerDollar_MPU):
    N=2**version                                # Number of SHA-3 operations (search space)
    SHA3perYear=SecondsPerYear/SHA3time         # Number of SHA-3 operations per year per collision-search engine

    theta = 2**-top_zero_bits 
    mem_unit=version/8 + (version/8 - math.floor(top_zero_bits/8)) + 6        # Bytes per memory unit
    w=(Money - p * SHA3gates / GatesPerDollar_MPU[YearIndex]) * BytesPerDollar_HDD[YearIndex] / mem_unit  # Number of memory units I can buy
    LogYears = 0; LogMemUnits = 0; LogEngUnits = 0; SHA3inSeconds = 0
    if w > 0:
        LogMemUnits = math.log2(w)
        LogEngUnits = math.log2(p)
        LogYears = math.log2((math.sqrt(math.pi*N/2)/p + 2.5/theta) * SHA3time/SecondsPerYear)
        SHA3inSeconds = math.log2((math.sqrt(math.pi*N/2)/p + 2.5/theta) * SHA3time)

    return LogYears, LogMemUnits, mem_unit, LogEngUnits, SHA3inSeconds

############################################################################################
#### SHA3-256

version = 256                           # SHA3-256 
SHA3gates = 10500 * 1.2                 # Number of GEs occupied by Akin et al.'s implementation (SMH option), scaled to include initialization and absorb stages
SHA3time = (54.95e-9 * (45/90)**2)*1.5  # Latency of implementation (scaled to 45nm from 90nm, scaled to include initialization and absorb stages )
node = 45                               # 45nm

print ("\nSHA3-" +repr(version)+ " on " +repr(node)+ "nm node")
print ("-------------------")
print ("Akin et al. implementation using 90nm: 54.95nsec/Keccak computation, 10.5KGE. Area and timing results are scaled to 45nm and SHA-3")

MinYearsSHA3 = [[None for i in range(21)] for j in range(7)]
MemBytesSHA3 = [[None for i in range(21)] for j in range(7)]
EngUnitsSHA3 = [[None for i in range(21)] for j in range(7)]

top_zero_bits = 74   #### NOTE: this can be tuned per option

for k in range(0, 7):
    print ("SHA3-256: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    engines = 2**(i+j/10)
                    LogYears, LogMemUnits, mem_unit, LogEngUnits, SHA3inSeconds = SHA3_estimator(version, SHA3gates, SHA3time, YearIndex, MoneyOptions[k], engines, top_zero_bits, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(mem_unit*2**LogMemUnits); EngUnits = LogEngUnits; t = SHA3inSeconds
            MinYearsSHA3[k][YearIndex] = MinLogYears
            MemBytesSHA3[k][YearIndex] = MemBytes
            EngUnitsSHA3[k][YearIndex] = EngUnits  
            #print ("(sqrt(Pi*N/2)/p + 2.5/theta) * SHA3-256 in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSHA3[k]); print ("Log(memory bytes):", MemBytesSHA3[k]); print ("Log(engine units):", EngUnitsSHA3[k], "\n")

ProjMinYearsSHA3 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSHA3 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSHA3 = [[None for i in range(9)] for j in range(7)]

top_zero_bits = 77   #### NOTE: this can be tuned per option

for k in range(0, 7):    
    print ("SHA3-256 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                engines = 2**(i+j/10)
                LogYears, LogMemUnits, mem_unit, LogEngUnits, SHA3inSeconds = SHA3_estimator(version, SHA3gates, SHA3time, YearIndex, MoneyOptions[k], engines, top_zero_bits, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(mem_unit*2**LogMemUnits); EngUnits = LogEngUnits; t = SHA3inSeconds
        ProjMinYearsSHA3[k][YearIndex] = MinLogYears
        ProjMemBytesSHA3[k][YearIndex] = MemBytes
        ProjEngUnitsSHA3[k][YearIndex] = EngUnits        
        #print ("(sqrt(Pi*N/2)/p + 2.5/theta) * SHA3-256 in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSHA3[k]); print ("Log(memory bytes):", ProjMemBytesSHA3[k]); print ("Log(engine units):", ProjEngUnitsSHA3[k], "\n")

############################################################################################
#### SHA3-384

version = 384                           # SHA3-384 
SHA3gates = 10500 * 1.2                 # Number of GEs occupied by Akin et al.'s implementation (SMH option), scaled to include initialization and absorb stages
SHA3time = (54.95e-9 * (45/90)**2)*1.5  # Latency of implementation (scaled to 45nm from 90nm, scaled to include initialization and absorb stages )
node = 45                               # 45nm

print ("\nSHA3-" +repr(version)+ " on " +repr(node)+ "nm node")
print ("-------------------")
print ("Akin et al. implementation using 90nm: 54.95nsec/Keccak computation, 10.5KGE. Area and timing results are scaled to 45nm and SHA-3")

MinYearsSHA3_384 = [[None for i in range(21)] for j in range(7)]
MemBytesSHA3_384 = [[None for i in range(21)] for j in range(7)]
EngUnitsSHA3_384 = [[None for i in range(21)] for j in range(7)]

top_zero_bits = 74   #### NOTE: this can be tuned per option

for k in range(0, 7):
    print ("SHA3-384: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    engines = 2**(i+j/10)
                    LogYears, LogMemUnits, mem_unit, LogEngUnits, SHA3inSeconds = SHA3_estimator(version, SHA3gates, SHA3time, YearIndex, MoneyOptions[k], engines, top_zero_bits, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(mem_unit*2**LogMemUnits); EngUnits = LogEngUnits; t = SHA3inSeconds
            MinYearsSHA3_384[k][YearIndex] = MinLogYears
            MemBytesSHA3_384[k][YearIndex] = MemBytes
            EngUnitsSHA3_384[k][YearIndex] = EngUnits  
            #print ("(sqrt(Pi*N/2)/p + 2.5/theta) * SHA3-384 in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSHA3_384[k]); print ("Log(memory bytes):", MemBytesSHA3_384[k]); print ("Log(engine units):", EngUnitsSHA3_384[k], "\n")

ProjMinYearsSHA3_384 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSHA3_384 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSHA3_384 = [[None for i in range(9)] for j in range(7)]

top_zero_bits = 77   #### NOTE: this can be tuned per option

for k in range(0, 7):    
    print ("SHA3-384 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                engines = 2**(i+j/10)
                LogYears, LogMemUnits, mem_unit, LogEngUnits, SHA3inSeconds = SHA3_estimator(version, SHA3gates, SHA3time, YearIndex, MoneyOptions[k], engines, top_zero_bits, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(mem_unit*2**LogMemUnits); EngUnits = LogEngUnits; t = SHA3inSeconds
        ProjMinYearsSHA3_384[k][YearIndex] = MinLogYears
        ProjMemBytesSHA3_384[k][YearIndex] = MemBytes
        ProjEngUnitsSHA3_384[k][YearIndex] = EngUnits        
        #print ("(sqrt(Pi*N/2)/p + 2.5/theta) * SHA3-384 in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSHA3_384[k]); print ("Log(memory bytes):", ProjMemBytesSHA3_384[k]); print ("Log(engine units):", ProjEngUnitsSHA3_384[k], "\n")

############################################################################################
#### SIKE security estimator

def SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, Money, memory, BytesPerDollar_HDD, GatesPerDollar_MPU):
    SIKEtime45nm = SIKEtime              # Latency of half-degree isogeny implementation by the proposed implementation on 45nm
    t=SecondsPerYear/SIKEtime45nm        # Number of half-degree isogeny operations per year per collision-search engine
    
    if version == 377:         # Determine search space          
        if isogeny == 2:
            e2 = 191
            N=2**((e2-1)/2)
        else:
            e3 = 117
            N=3**((e3-1)/2)     
    elif version == 434:
        e2 = 216
        N=2**(e2/2-1)
    elif version == 503:
        e2 = 250
        N=2**(e2/2-1)
    elif version == 546:
        e2 = 273
        N=2**((e2-1)/2)
    elif version == 610:
        e2 = 305
        N=2**((e2-1)/2)
    elif version == 697:
        if isogeny == 2: 
            e2 = 356
            N=2**(e2/2-1)
        else:
            e3 = 215
            N=3**((e3-1)/2)
    elif version == 751:
        e2 = 372
        N=2**(e2/2-1)

    mem_unit=math.ceil((2*math.log2(N) + math.log2(20))/8);   # Bytes per memory unit
    w=memory/mem_unit   # Memory units
    p=(Money - (1/BytesPerDollar_HDD[YearIndex] * w * mem_unit))*GatesPerDollar_MPU[YearIndex]/SIKEgates  # Number of engines I can buy
    LogYears = 0; LogMemUnits = 0; LogEngUnits = 0; SIKEinSeconds = 0
    if p > 0:
        LogMemUnits = math.log2(w)
        LogEngUnits = math.log2(p)
        LogYears = math.log2(2.5*math.sqrt(N**3/w)/(p * t))
        SIKEinSeconds = math.log2(2.5*math.sqrt(N**3/w) * SIKEtime45nm)

    return LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds

############################################################################################
#### SIKEp377, 2-isogeny attack

version = 377               # SIKE377  
isogeny = 2
SIKEgates = 341300          # Number of GEs occupied by the proposed implementation
SIKEtime = 2.347e-3         # Latency of half-degree isogeny implementation on 45nm
node = 45                   # 45nm

print ("\nSIKEp" +repr(version)+ " on " +repr(node)+ "nm node, using " +repr(isogeny)+ "-isogenies")
print ("-------------------")
print ("Proposed implementation using 45nm, radix = 32: 2.347msec/half-degree isogeny, area of 341,300 GE")

MinYearsSIKEp377 = [[None for i in range(21)] for j in range(7)]
MemBytesSIKEp377 = [[None for i in range(21)] for j in range(7)]
EngUnitsSIKEp377 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("SIKEp377: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    memory = 2**(i+j/10)
                    LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
            MinYearsSIKEp377[k][YearIndex] = MinLogYears
            MemBytesSIKEp377[k][YearIndex] = MemBytes
            EngUnitsSIKEp377[k][YearIndex] = EngUnits            
            #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSIKEp377[k]); print ("Log(memory bytes):", MemBytesSIKEp377[k]); print ("Log(engine units):", EngUnitsSIKEp377[k], "\n")

ProjMinYearsSIKEp377 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSIKEp377 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSIKEp377 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):    
    print ("SIKEp377 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                memory = 2**(i+j/10)
                LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
        ProjMinYearsSIKEp377[k][YearIndex] = MinLogYears
        ProjMemBytesSIKEp377[k][YearIndex] = MemBytes
        ProjEngUnitsSIKEp377[k][YearIndex] = EngUnits            
        #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSIKEp377[k]); print ("Log(memory bytes):", ProjMemBytesSIKEp377[k]); print ("Log(engine units):", ProjEngUnitsSIKEp377[k], "\n")

############################################################################################
#### SIKEp434

version = 434               # SIKE434  
isogeny = 2
SIKEgates = 372200          # Number of GEs occupied by the proposed implementation
SIKEtime = 3.253e-3         # Latency of half-degree isogeny implementation on 45nm
node = 45                   # 45nm

print ("\nSIKEp" +repr(version)+ " on " +repr(node)+ "nm node, using " +repr(isogeny)+ "-isogenies")
print ("-------------------")
print ("Proposed implementation using 45nm, radix = 32: 3.253msec/half-degree isogeny, area of 372,200 GE")

MinYearsSIKEp434 = [[None for i in range(21)] for j in range(7)]
MemBytesSIKEp434 = [[None for i in range(21)] for j in range(7)]
EngUnitsSIKEp434 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("SIKEp434: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    memory = 2**(i+j/10)
                    LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
            MinYearsSIKEp434[k][YearIndex] = MinLogYears
            MemBytesSIKEp434[k][YearIndex] = MemBytes
            EngUnitsSIKEp434[k][YearIndex] = EngUnits            
            #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSIKEp434[k]); print ("Log(memory bytes):", MemBytesSIKEp434[k]); print ("Log(engine units):", EngUnitsSIKEp434[k], "\n")

ProjMinYearsSIKEp434 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSIKEp434 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSIKEp434 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):    
    print ("SIKEp434 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                memory = 2**(i+j/10)
                LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
        ProjMinYearsSIKEp434[k][YearIndex] = MinLogYears
        ProjMemBytesSIKEp434[k][YearIndex] = MemBytes
        ProjEngUnitsSIKEp434[k][YearIndex] = EngUnits            
        #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSIKEp434[k]); print ("Log(memory bytes):", ProjMemBytesSIKEp434[k]); print ("Log(engine units):", ProjEngUnitsSIKEp434[k], "\n")

############################################################################################
#### SIKEp503

version = 503               # SIKE503  
isogeny = 2
SIKEgates = 409500          # Number of GEs occupied by the proposed implementation
SIKEtime = 4.814e-3         # Latency of half-degree isogeny implementation on 45nm
node = 45                   # 45nm

print ("\nSIKEp" +repr(version)+ " on " +repr(node)+ "nm node, using " +repr(isogeny)+ "-isogenies")
print ("-------------------")
print ("Proposed implementation using 45nm, radix = 32: 4.814msec/half-degree isogeny, area of 409,500 GE")

MinYearsSIKEp503 = [[None for i in range(21)] for j in range(7)]
MemBytesSIKEp503 = [[None for i in range(21)] for j in range(7)]
EngUnitsSIKEp503 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("SIKEp503: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    memory = 2**(i+j/10)
                    LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
            MinYearsSIKEp503[k][YearIndex] = MinLogYears
            MemBytesSIKEp503[k][YearIndex] = MemBytes
            EngUnitsSIKEp503[k][YearIndex] = EngUnits            
            #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSIKEp503[k]); print ("Log(memory bytes):", MemBytesSIKEp503[k]); print ("Log(engine units):", EngUnitsSIKEp503[k], "\n")

ProjMinYearsSIKEp503 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSIKEp503 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSIKEp503 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):    
    print ("SIKEp503 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                memory = 2**(i+j/10)
                LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
        ProjMinYearsSIKEp503[k][YearIndex] = MinLogYears
        ProjMemBytesSIKEp503[k][YearIndex] = MemBytes
        ProjEngUnitsSIKEp503[k][YearIndex] = EngUnits            
        #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSIKEp503[k]); print ("Log(memory bytes):", ProjMemBytesSIKEp503[k]); print ("Log(engine units):", ProjEngUnitsSIKEp503[k], "\n")

############################################################################################
#### SIKEp546

version = 546               # SIKE546
isogeny = 2
SIKEgates = 441100          # Number of GEs occupied by the proposed implementation
SIKEtime = 7.095e-3         # Latency of half-degree isogeny implementation on 45nm
node = 45                   # 45nm

print ("\nSIKEp" +repr(version)+ " on " +repr(node)+ "nm node, using " +repr(isogeny)+ "-isogenies")
print ("-------------------")
print ("Proposed implementation using 45nm, radix = 32: 7.095msec/half-degree isogeny, area of 441,100 GE")

MinYearsSIKEp546 = [[None for i in range(21)] for j in range(7)]
MemBytesSIKEp546 = [[None for i in range(21)] for j in range(7)]
EngUnitsSIKEp546 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("SIKEp546: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    memory = 2**(i+j/10)
                    LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
            MinYearsSIKEp546[k][YearIndex] = MinLogYears
            MemBytesSIKEp546[k][YearIndex] = MemBytes
            EngUnitsSIKEp546[k][YearIndex] = EngUnits            
            #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSIKEp546[k]); print ("Log(memory bytes):", MemBytesSIKEp546[k]); print ("Log(engine units):", EngUnitsSIKEp546[k], "\n")

ProjMinYearsSIKEp546 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSIKEp546 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSIKEp546 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):    
    print ("SIKEp546 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                memory = 2**(i+j/10)
                LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
        ProjMinYearsSIKEp546[k][YearIndex] = MinLogYears
        ProjMemBytesSIKEp546[k][YearIndex] = MemBytes
        ProjEngUnitsSIKEp546[k][YearIndex] = EngUnits            
        #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSIKEp546[k]); print ("Log(memory bytes):", ProjMemBytesSIKEp546[k]); print ("Log(engine units):", ProjEngUnitsSIKEp546[k], "\n")

############################################################################################
#### SIKEp610

version = 610               # SIKE610  
isogeny = 2
SIKEgates = 748000          # Number of GEs occupied by the proposed implementation
SIKEtime = 5.803e-3         # Latency of half-degree isogeny implementation on 45nm
node = 45                   # 45nm

print ("\nSIKEp" +repr(version)+ " on " +repr(node)+ "nm node, using " +repr(isogeny)+ "-isogenies")
print ("-------------------")
print ("Proposed implementation using 45nm, radix = 64: 5.803msec/half-degree isogeny, area of 748,000 GE")

MinYearsSIKEp610 = [[None for i in range(21)] for j in range(7)]
MemBytesSIKEp610 = [[None for i in range(21)] for j in range(7)]
EngUnitsSIKEp610 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("SIKEp610: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    memory = 2**(i+j/10)
                    LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
            MinYearsSIKEp610[k][YearIndex] = MinLogYears
            MemBytesSIKEp610[k][YearIndex] = MemBytes
            EngUnitsSIKEp610[k][YearIndex] = EngUnits            
            #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSIKEp610[k]); print ("Log(memory bytes):", MemBytesSIKEp610[k]); print ("Log(engine units):", EngUnitsSIKEp610[k], "\n")

ProjMinYearsSIKEp610 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSIKEp610 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSIKEp610 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):    
    print ("SIKEp610 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                memory = 2**(i+j/10)
                LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
        ProjMinYearsSIKEp610[k][YearIndex] = MinLogYears
        ProjMemBytesSIKEp610[k][YearIndex] = MemBytes
        ProjEngUnitsSIKEp610[k][YearIndex] = EngUnits            
        #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSIKEp610[k]); print ("Log(memory bytes):", ProjMemBytesSIKEp610[k]); print ("Log(engine units):", ProjEngUnitsSIKEp610[k], "\n")

############################################################################################
#### SIKEp697

version = 697               # SIKE697                
isogeny = 2
SIKEgates = 798900          # Number of GEs occupied by the proposed implementation
SIKEtime = 8.595e-3         # Latency of half-degree isogeny implementation on 45nm
node = 45                   # 45nm

print ("\nSIKEp" +repr(version)+ " on " +repr(node)+ "nm node, using " +repr(isogeny)+ "-isogenies")
print ("-------------------")
print ("Proposed implementation using 45nm, radix = 64: 8.595msec/half-degree isogeny, area of 798,900 GE")

MinYearsSIKEp697 = [[None for i in range(21)] for j in range(7)]
MemBytesSIKEp697 = [[None for i in range(21)] for j in range(7)]
EngUnitsSIKEp697 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("SIKEp697: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    memory = 2**(i+j/10)
                    LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
            MinYearsSIKEp697[k][YearIndex] = MinLogYears
            MemBytesSIKEp697[k][YearIndex] = MemBytes
            EngUnitsSIKEp697[k][YearIndex] = EngUnits            
            #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSIKEp697[k]); print ("Log(memory bytes):", MemBytesSIKEp697[k]); print ("Log(engine units):", EngUnitsSIKEp697[k], "\n")

ProjMinYearsSIKEp697 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSIKEp697 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSIKEp697 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):    
    print ("SIKEp697 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                memory = 2**(i+j/10)
                LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
        ProjMinYearsSIKEp697[k][YearIndex] = MinLogYears
        ProjMemBytesSIKEp697[k][YearIndex] = MemBytes
        ProjEngUnitsSIKEp697[k][YearIndex] = EngUnits            
        #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSIKEp697[k]); print ("Log(memory bytes):", ProjMemBytesSIKEp697[k]); print ("Log(engine units):", ProjEngUnitsSIKEp697[k], "\n")

############################################################################################
#### SIKEp751

version = 751               # SIKE751  
isogeny = 2
SIKEgates = 822300          # Number of GEs occupied by the proposed implementation
SIKEtime = 9.703e-3         # Latency of half-degree isogeny implementation on 45nm
node = 45                   # 45nm

print ("\nSIKEp" +repr(version)+ " on " +repr(node)+ "nm node, using " +repr(isogeny)+ "-isogenies")
print ("-------------------")
print ("Proposed implementation using 45nm, radix = 64: 9.703msec/half-degree isogeny, area of 822,300 GE")

MinYearsSIKEp751 = [[None for i in range(21)] for j in range(7)]
MemBytesSIKEp751 = [[None for i in range(21)] for j in range(7)]
EngUnitsSIKEp751 = [[None for i in range(21)] for j in range(7)]

for k in range(0, 7):
    print ("SIKEp751: results per year (2000-2020), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 21):
        lock = 0
        if CostMPU[YearIndex] != None: 
            for i in range(10, 100):
                for j in range(0, 10):
                    memory = 2**(i+j/10)
                    LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, BytesPerDollar_HDD, GatesPerDollar_MPU)
                    if LogYears != 0:  
                        if lock == 0: MinLogYears = LogYears; lock = 1 
                        if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
            MinYearsSIKEp751[k][YearIndex] = MinLogYears
            MemBytesSIKEp751[k][YearIndex] = MemBytes
            EngUnitsSIKEp751[k][YearIndex] = EngUnits            
            #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", MinYearsSIKEp751[k]); print ("Log(memory bytes):", MemBytesSIKEp751[k]); print ("Log(engine units):", EngUnitsSIKEp751[k], "\n")

ProjMinYearsSIKEp751 = [[None for i in range(9)] for j in range(7)]
ProjMemBytesSIKEp751 = [[None for i in range(9)] for j in range(7)]
ProjEngUnitsSIKEp751 = [[None for i in range(9)] for j in range(7)]

for k in range(0, 7):    
    print ("SIKEp751 (projection): results every 5 years (2000-2040), budget (millions of dollars) = " +repr(MoneyOptions[k]/10**6))

    for YearIndex in range(0, 9):
        lock = 0
        for i in range(10, 100):
            for j in range(0, 10):
                memory = 2**(i+j/10)
                LogYears, LogMemUnits, LogEngUnits, SIKEinSeconds = SIKE_estimator(version, isogeny, SIKEgates, SIKEtime, YearIndex, MoneyOptions[k], memory, ProjBytesPerDollar_HDD, ProjGatesPerDollar_MPU)
                if LogYears != 0:  
                    if lock == 0: MinLogYears = LogYears; lock = 1 
                    if LogYears <= MinLogYears: MinLogYears = LogYears; MemBytes = math.log2(memory); EngUnits = LogEngUnits; t = SIKEinSeconds
        ProjMinYearsSIKEp751[k][YearIndex] = MinLogYears
        ProjMemBytesSIKEp751[k][YearIndex] = MemBytes
        ProjEngUnitsSIKEp751[k][YearIndex] = EngUnits            
        #print ("2.5*sqrt(N^3/w) * SIKE in seconds: 2 ^", t)
    print ("Log(years):", ProjMinYearsSIKEp751[k]); print ("Log(memory bytes):", ProjMemBytesSIKEp751[k]); print ("Log(engine units):", ProjEngUnitsSIKEp751[k], "\n")

############################################################################################
#### Graph of security estimates (in years) using historical prices of memory (bytes) and
#### computing resources (gates), years 2000-2020 

def grapher_historical(k):
    x = np.linspace(0, 20, 21)        
    y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12 = YearsAES128[k], YearsAES192[k], YearsAES256[k], MinYearsSHA3[k], MinYearsSHA3_384[k], MinYearsSIKEp377[k], MinYearsSIKEp434[k], MinYearsSIKEp503[k], MinYearsSIKEp546[k], MinYearsSIKEp610[k], MinYearsSIKEp697[k], MinYearsSIKEp751[k]

    # Setting the figure size and resolution
    fig, ax = plt.subplots(figsize=(10, 3), dpi=300)

    # Changing spine style
    plt.axes().xaxis.set_minor_locator(MultipleLocator(1))
    plt.axes().yaxis.set_minor_locator(MultipleLocator(5))
    plt.grid(color='gray', ls = '-.', lw = 0.25)

    # Setting the color, linewidth, linestyle and legend
    plt.plot(x, y1, color="crimson", linewidth=1.0, linestyle="-", label="AES128")
    plt.plot(x, y2, color="crimson", linewidth=1.0, linestyle="--", label="AES192")
    plt.plot(x, y3, color="crimson", linewidth=1.0, linestyle="-.", label="AES256")
    plt.plot(x, y4, color="tab:brown", linewidth=1.0, linestyle="--", label="SHA3-256")
    plt.plot(x, y5, color="tab:brown", linewidth=1.0, linestyle="-.", label="SHA3-384")
    plt.plot(x, y6, color="royalblue", linewidth=1.0, linestyle="-", label="SIKEp377")
    plt.plot(x, y7, color="royalblue", linewidth=1.0, linestyle="--", label="SIKEp434")
    plt.plot(x, y8, color="royalblue", linewidth=1.0, linestyle="-.", label="SIKEp503")
    plt.plot(x, y9, color="royalblue", linewidth=1.0, linestyle=(0, (5, 1)), label="SIKEp546")
    plt.plot(x, y10, color="royalblue", linewidth=1.0, linestyle=(0, (5, 10)), label="SIKEp610")
    plt.plot(x, y11, color="royalblue", linewidth=1.0, linestyle=(0, (5, 5)), label="SIKEp697")
    plt.plot(x, y12, color="royalblue", linewidth=1.0, linestyle=(0, (1, 5)), label="SIKEp751")
    leg = plt.legend(loc='upper right', prop={'size': 6}, frameon=True)
    plt.draw() # Draw the figure so you can find the positon of the legend 

    # Get the bounding box of the original legend
    bb = leg.get_bbox_to_anchor().inverse_transformed(ax.transAxes)

    # Change to location of the legend 
    xOffset = -0.01
    bb.x0 += xOffset
    bb.x1 += xOffset
    leg.set_bbox_to_anchor(bb, transform = ax.transAxes)

    # Use Latex to set tick labels
    plt.xticks([0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20], [r'2000', r'$2002$', r'$2004$', r'$2006$', r'$2008$', r'$2010$', r'$2012$', r'$2014$', r'$2016$', r'$2018$', r'$2020$'])
    plt.xticks(fontsize=8, rotation=0)
    plt.yticks(fontsize=8, rotation=0)
    plt.xlabel('Year')  # add x-label
    plt.ylabel('Log(Years)')  # add y-label
    if titlefigure == 'on': plt.title('Security estimates in years, budget = US$' +repr(int(MoneyOptions[k]/1e6))+ ' million')  # add title

    # Setting the boundaries of the figure
    plt.xlim(x.min()*1.0, x.max()*1.0)
    plt.ylim(0, y3[19]*1.5)

    plt.gcf().subplots_adjust(bottom=0.12)
    plt.show() # show figure
    fig.savefig("historical_estimates_" +repr(int(MoneyOptions[k]/1e6))+ "million.png", dpi = 300) # save figure

    return
    
############################################################################################
#### Graphing for all the budget options
   
for i in range(0, 7):
    grapher_historical(i)

############################################################################################
#### Graph of security estimates (in years) using projection of prices of memory (bytes) and
#### computing resources (gates), years 2000-2040
#### Uses historical prices for 2000-2020, projections for 2025-2040 

def grapher_projection(k):
    x = np.linspace(0, 8, 9)        
    y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12 = ProjYearsAES128[k], ProjYearsAES192[k], ProjYearsAES256[k], ProjMinYearsSHA3[k], ProjMinYearsSHA3_384[k], ProjMinYearsSIKEp377[k], ProjMinYearsSIKEp434[k], ProjMinYearsSIKEp503[k], ProjMinYearsSIKEp546[k], ProjMinYearsSIKEp610[k], ProjMinYearsSIKEp697[k], ProjMinYearsSIKEp751[k]

    # Setting the figure size and resolution
    fig, ax = plt.subplots(figsize=(10, 3), dpi=300)

    # Changing spine style
    plt.axes().xaxis.set_minor_locator(MultipleLocator(1))
    plt.axes().yaxis.set_minor_locator(MultipleLocator(5))
    plt.grid(color='gray', ls = '-.', lw = 0.25)

    # Setting the color, linewidth, linestyle and legend
    plt.plot(x, y1, color="crimson", linewidth=1.3, linestyle="-", label="AES128")
    plt.plot(x, y2, color="crimson", linewidth=1.3, linestyle="--", label="AES192")
    plt.plot(x, y3, color="crimson", linewidth=1.3, linestyle="-.", label="AES256")
    plt.plot(x, y4, color="tab:brown", linewidth=1.3, linestyle="--", label="SHA3-256")
    plt.plot(x, y5, color="tab:brown", linewidth=1.3, linestyle="-.", label="SHA3-384")
    plt.plot(x, y6, color="royalblue", linewidth=1.3, linestyle="-", label="SIKEp377")
    plt.plot(x, y7, color="royalblue", linewidth=1.3, linestyle=(0, (5, 1)), label="SIKEp434")
    plt.plot(x, y8, color="royalblue", linewidth=1.3, linestyle="-.", label="SIKEp503")
    plt.plot(x, y9, color="royalblue", linewidth=1.3, linestyle="--", label="SIKEp546")
    plt.plot(x, y10, color="royalblue", linewidth=1.3, linestyle=(0, (5, 5)), label="SIKEp610")
    plt.plot(x, y11, color="royalblue", linewidth=1.3, linestyle=(0, (5, 10)), label="SIKEp697")
    plt.plot(x, y12, color="royalblue", linewidth=1.3, linestyle=(0, (1, 5)), label="SIKEp751")
    
    if titlefigure == 'on':
        leg = plt.legend(loc='upper right', prop={'size': 7}, frameon=True)
        plt.draw() # Draw the figure so you can find the positon of the legend 

        # Get the bounding box of the original legend
        bb = leg.get_bbox_to_anchor().inverse_transformed(ax.transAxes)

        # Change to location of the legend 
        xOffset = -0.01
        bb.x0 += xOffset
        bb.x1 += xOffset
        leg.set_bbox_to_anchor(bb, transform = ax.transAxes)

    # Use Latex to set tick labels
    plt.xticks([0, 1, 2, 3, 4, 5, 6, 7, 8], [r'2000', r'$2005$', r'$2010$', r'$2015$', r'$2020$', r'$2025$', r'$2030$', r'$2035$', r'$2040$'])
    plt.xticks(fontsize=8, rotation=0)
    plt.yticks(fontsize=8, rotation=0)
    plt.xlabel('Year')  # add x-label
    plt.ylabel('Log(Years)')  # add y-label
    if titlefigure == 'on': plt.title('Security estimates in years (projection), budget = US$' +repr(int(MoneyOptions[k]/1e6))+ ' million')  # add title
    
    plt.text(0.8,  y1[1]-12, 'AES128', color='crimson', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(1.7,  y4[2]-12, 'SHA3-256', color='tab:brown', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8,  y6[1]+2, 'SIKEp377', color='royalblue', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8,  y7[1]+2, 'SIKEp434', color='royalblue', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8, y8[1]-12, 'SIKEp503', color='royalblue', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    if k < 3:
        plt.text(0.8, y2[1]+2, 'AES192', color='crimson', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
        plt.text(1.7, y5[2]+1, 'SHA3-384', color='tab:brown', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    else:
        plt.text(0.8, y2[1]-10, 'AES192', color='crimson', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
        plt.text(1.7, y5[2]-11, 'SHA3-384', color='tab:brown', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8, y9[1]+2, 'SIKEp546', color='royalblue', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8, y10[1]+2, 'SIKEp610', color='royalblue', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8, y3[1]-12, 'AES256', color='crimson', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8, y11[1]+2, 'SIKEp697', color='royalblue', fontsize=7, verticalalignment='bottom', horizontalalignment='left')
    plt.text(0.8, y12[1]+2, 'SIKEp751', color='royalblue', fontsize=7, verticalalignment='bottom', horizontalalignment='left')

    # Setting the boundaries of the figure
    plt.xlim(x.min()*1.0, x.max()*1.0)
    plt.ylim(0, y3[8]*1.5)

    plt.gcf().subplots_adjust(bottom=0.12)
    plt.show() # show figure
    fig.savefig("projection_estimates_" +repr(int(MoneyOptions[k]/1e6))+ "million.png", dpi = 300) # save figure

    return
    
############################################################################################
#### Graphing for all the budget options
      
for i in range(0, 7):
    grapher_projection(i)

############################################################################################
#### Historical graph of number of components (bytes/gates) that can be bought per dollar

x = np.linspace(0, 20, 21)
x4 = [i for i in range(0,21)]
LogBytesPerDollar_HDD = [None for i in range(21)]
LogBytesPerDollar_DRAM = [None for i in range(21)]
LogBytesPerDollar_SSD = [None for i in range(21)]
LogBytesPerDollar_HDD = [None for i in range(21)]
LogGatesPerDollar_MPU = [None for i in range(21)]
LogGatesPerDollar_Linley = [None for i in range(21)]
LogGatesPerDollar_ITRS = [None for i in range(21)]
LogBytesPerGate = [None for i in range(21)]

for i in range(0,21):
    if BytesPerDollar_HDD[i] != None:
        LogBytesPerDollar_HDD[i] = math.log2(BytesPerDollar_HDD[i])
    if BytesPerDollar_DRAM[i] != None:
        LogBytesPerDollar_DRAM[i] = math.log2(BytesPerDollar_DRAM[i])
    if BytesPerDollar_SSD[i] != None:
        LogBytesPerDollar_SSD[i] = math.log2(BytesPerDollar_SSD[i])
    if GatesPerDollar_MPU[i] != None:
        LogGatesPerDollar_MPU[i] = math.log2(GatesPerDollar_MPU[i])
    if GatesPerDollar_Linley[i] != None:
        LogGatesPerDollar_Linley[i] = math.log2(GatesPerDollar_Linley[i])
    if GatesPerDollar_ITRS[i] != None:
        LogGatesPerDollar_ITRS[i] = math.log2(GatesPerDollar_ITRS[i])
    if BytesPerGate[i] != None:
        LogBytesPerGate[i] = math.log2(BytesPerGate[i])
        
y1, y2, y3, y4, y5, y6, y7 = LogBytesPerDollar_HDD, LogGatesPerDollar_MPU, LogGatesPerDollar_Linley, LogGatesPerDollar_ITRS, LogBytesPerGate, LogBytesPerDollar_DRAM, LogBytesPerDollar_SSD

print (LogBytesPerDollar_HDD)
print (LogBytesPerDollar_DRAM)
print (LogBytesPerDollar_SSD)
print (LogGatesPerDollar_MPU)
print (LogGatesPerDollar_Linley)
print (LogGatesPerDollar_ITRS)
print (LogBytesPerGate)

# Setting the figure size and resolution
fig, ax = plt.subplots(figsize=(10, 3), dpi=300)

# Changing spine style
plt.axes().xaxis.set_minor_locator(MultipleLocator(1))
plt.axes().yaxis.set_minor_locator(MultipleLocator(5))
plt.grid(color='gray', ls = '-.', lw = 0.25)

# Setting the color, linewidth, linestyle and legend
plt.plot(x, y1, color="crimson", linewidth=1.0, linestyle="-", label="Bytes/dollar (HDD)")
plt.plot(x, y2, color="royalblue", linewidth=1.0, linestyle="-", label="Gates/dollar (MPU)")
plt.scatter(x, y3, color="royalblue", s = 7.0, marker='^', label="Gates/dollar (Linley Group)")
plt.scatter(x, y4, color="aquamarine", s = 5.0, marker='x', label="Gates/dollar (ITRS 2001-2007, forecast)")
plt.plot(x, y5, color="olivedrab", linewidth=1.5, linestyle="-", label="Bytes (HDD)/gate (MPU) ratio")
plt.plot(x, y6, color="crimson", linewidth=1.0, linestyle="--", label="Bytes/dollar (DRAM)")
plt.plot(x, y7, color="crimson", linewidth=1.0, linestyle="-.", label="Bytes/dollar (SSD)")
plt.legend(loc='upper left', prop={'size': 6}, frameon=True)

# Use Latex to set tick labels
plt.xticks([0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20], [r'$2000$', r'$2002$', r'$2004$', r'$2006$', r'$2008$', r'$2010$', r'$2012$', r'$2014$', r'$2016$', r'$2018$', r'$2020$'])
plt.xticks(fontsize=8, rotation=0)
plt.yticks(fontsize=8, rotation=0)
plt.xlabel('Year')  # add x-label
plt.ylabel('Log(components/dollar)')  # add y-label
if titlefigure == 'on': plt.title('Historical prices of memory and gates (MPUs), 2000-2020')  # add title

# Setting the boundaries of the figure
plt.xlim(x.min()*1.0, x.max()*1.0)
plt.ylim(5, y1[20]*1.5)

plt.gcf().subplots_adjust(bottom=0.12)
plt.show() # show figure
fig.savefig("historical_mpu_hdd.png", dpi = 300) # save figure