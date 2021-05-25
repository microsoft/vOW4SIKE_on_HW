
lazy val root = (project in file(".")).
  settings(
    // inThisBuild(List(
    //   organization := "com.github.spinalhdl",
    //   scalaVersion := "2.11.6",
    //   version      := "0.1.0-SNAPSHOT"
    // )),
    // name := "superproject"
    inThisBuild(List(
      organization := "com.github.spinalhdl",
      scalaVersion := "2.11.12",
      version      := "2.0.0"
    )),
    libraryDependencies ++= Seq(
        "com.github.spinalhdl" % "spinalhdl-core_2.11" % "1.3.6",
        "com.github.spinalhdl" % "spinalhdl-lib_2.11" % "1.3.6",
        "org.scalatest" % "scalatest_2.11" % "2.2.1",
        "org.yaml" % "snakeyaml" % "1.8"
    ),
    name := "superproject"
  ).dependsOn(vexRiscv)

// lazy val vexRiscv = RootProject(uri("git://github.com/SpinalHDL/VexRiscv.git"))

//If you want a specific git commit : 
// lazy val vexRiscv = RootProject(uri("git://github.com/SpinalHDL/VexRiscv.git#7ab04a128"))

//If you want a specific git commit : 2019-11-23
lazy val vexRiscv = RootProject(uri("git://github.com/SpinalHDL/VexRiscv.git#b290b25f7a292c98f50c81872923edc305f76a0d"))

//If the dependancy is localy on your computer : 
// lazy val vexRiscv = RootProject(file("../../../VexRiscv"))
 