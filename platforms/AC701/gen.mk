TARGET_DIR = $(shell pwd)

gen: $(TARGET).v

$(TARGET).v:
	make -C ../Murax TARGET=$(TARGET) TARGET_DIR=$(TARGET_DIR) 
	cp ../Murax/cpu0.yaml .

gen_clean:
	rm -rf $(TARGET).v
	rm -rf cpu0.yaml

