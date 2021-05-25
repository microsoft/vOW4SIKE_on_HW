TARGETS = $(shell grep "object Murax" src/main/scala/SIKE/Murax.scala | sed 's/object //' | sed 's/{//')

TARGET_DIR = .

ifndef TARGET
  $(error $(TARGET) Choose TARGET from list "$(TARGETS)", eg. "make TARGET=Murax")
endif

$(TARGET_DIR)/$(TARGET).v:
	sbt "runMain SIKE.$(TARGET) --verilog --targetDirectory $(TARGET_DIR)"

clean:
	rm -rf $(TARGET).v
	rm -rf cpu0.yaml

