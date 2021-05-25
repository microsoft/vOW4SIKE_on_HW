/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      SIKE accelerators plugins
 * 
*/

package SIKE

import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.misc.SizeMapping
import spinal.lib.com.jtag.Jtag
import spinal.lib.com.uart._
import spinal.lib.io.TriStateArray
import spinal.lib.misc.{InterruptCtrl, Prescaler, Timer}
import spinal.lib.soc.pinsec.{PinsecTimerCtrl, PinsecTimerCtrlExternal}
import vexriscv.demo._
import vexriscv.plugin._
import vexriscv.{VexRiscv, VexRiscvConfig, plugin}

  

// Define as BlackBox
class Apb3Fp2MontMultiplier() extends BlackBox {
  val io = new Bundle {
    val mainClk = in Bool
    val systemReset = in Bool
    val apb  = slave(Apb3(Apb3Config(addressWidth = 7,dataWidth = 32)))
  }

  //Map the current clock domain to the io.clk pin
  mapClockDomain(clock=io.mainClk, reset=io.systemReset)
}
 
// Define as BlackBox
class Apb3Controller() extends BlackBox {
  val io = new Bundle {
    val mainClk = in Bool
    val systemReset = in Bool
    val apb  = slave(Apb3(Apb3Config(addressWidth = 7,dataWidth = 32)))
  }

  //Map the current clock domain to the io.clk pin
  mapClockDomain(clock=io.mainClk, reset=io.systemReset)
}

 