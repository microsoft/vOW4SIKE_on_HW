################################################
sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=377/' Makefile
sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 2.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=377/' Makefile
sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=377/' Makefile
sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=377/' Makefile
sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 
 
sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=377/' Makefile
sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=377/' Makefile
sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

# sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
# sed -i 's/.*prime=.*/prime=377/' Makefile
# sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
# sed -i 's/.*DSP=.*/DSP=yes/' Makefile
# sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 5.0 [get_ports { clk }];/' board.xdc
# make clean; make 

# sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
# sed -i 's/.*prime=.*/prime=377/' Makefile
# sed -i 's/.*prime_round=.*/prime_round=384/' Makefile
# sed -i 's/.*DSP=.*/DSP=no/' Makefile
# sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
# make clean; make 

# sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
# sed -i 's/.*prime=.*/prime=377/' Makefile
# sed -i 's/.*prime_round=.*/prime_round=408/' Makefile
# sed -i 's/.*DSP=.*/DSP=yes/' Makefile
# sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
# make clean; make 

# sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
# sed -i 's/.*prime=.*/prime=377/' Makefile
# sed -i 's/.*prime_round=.*/prime_round=408/' Makefile
# sed -i 's/.*DSP=.*/DSP=no/' Makefile
# sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
# make clean; make 

# sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
# sed -i 's/.*prime=.*/prime=377/' Makefile
# sed -i 's/.*prime_round=.*/prime_round=408/' Makefile
# sed -i 's/.*DSP=.*/DSP=yes/' Makefile
# sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
# make clean; make 

# sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
# sed -i 's/.*prime=.*/prime=377/' Makefile
# sed -i 's/.*prime_round=.*/prime_round=408/' Makefile
# sed -i 's/.*DSP=.*/DSP=no/' Makefile
# sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
# make clean; make 

################################################
sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=448/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=448/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=448/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=448/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=448/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=448/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=456/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=456/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 5.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=442/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=442/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=459/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
sed -i 's/.*prime=.*/prime=434/' Makefile
sed -i 's/.*prime_round=.*/prime_round=459/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
make clean; make 

################################################
sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=512/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=512/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=512/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=512/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=512/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=512/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=528/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=528/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 5.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=510/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=510/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=510/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
sed -i 's/.*prime=.*/prime=503/' Makefile
sed -i 's/.*prime_round=.*/prime_round=510/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
make clean; make 

################################################
sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=16/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=32/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=64/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 9.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 4.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=24/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=768/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 5.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=782/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=34/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=782/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 6.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=765/' Makefile
sed -i 's/.*DSP=.*/DSP=yes/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
make clean; make 

sed -i 's/.*RADIX=.*/RADIX=51/' Makefile
sed -i 's/.*prime=.*/prime=751/' Makefile
sed -i 's/.*prime_round=.*/prime_round=765/' Makefile
sed -i 's/.*DSP=.*/DSP=no/' Makefile
sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period 8.0 [get_ports { clk }];/' board.xdc
make clean; make 

echo "bacth synthesis finished!"