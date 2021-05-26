###############################################
sed -i 's/.*RADIX =.*/RADIX = 16/' Makefile
sed -i 's/.*prime =.*/prime = 128/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 128/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
# ------------------------------------

###############################################
sed -i 's/.*RADIX =.*/RADIX = 32/' Makefile
sed -i 's/.*prime =.*/prime = 128/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 128/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
# ------------------------------------


###############################################
sed -i 's/.*RADIX =.*/RADIX = 16/' Makefile
sed -i 's/.*prime =.*/prime = 377/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 384/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
# ------------------------------------


 
sed -i 's/.*RADIX =.*/RADIX = 32/' Makefile
sed -i 's/.*prime =.*/prime = 377/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 384/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

  
 
sed -i 's/.*RADIX =.*/RADIX = 64/' Makefile
sed -i 's/.*prime =.*/prime = 377/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 384/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

  

sed -i 's/.*RADIX =.*/RADIX = 24/' Makefile
sed -i 's/.*prime =.*/prime = 377/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 384/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 34/' Makefile
sed -i 's/.*prime =.*/prime = 377/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 408/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 51/' Makefile
sed -i 's/.*prime =.*/prime = 377/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 408/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

################################################
sed -i 's/.*RADIX =.*/RADIX = 16/' Makefile
sed -i 's/.*prime =.*/prime = 434/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 448/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 32/' Makefile
sed -i 's/.*prime =.*/prime = 434/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 448/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 64/' Makefile
sed -i 's/.*prime =.*/prime = 434/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 448/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 24/' Makefile
sed -i 's/.*prime =.*/prime = 434/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 456/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 34/' Makefile
sed -i 's/.*prime =.*/prime = 434/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 442/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 51/' Makefile
sed -i 's/.*prime =.*/prime = 434/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 459/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

################################################
sed -i 's/.*RADIX =.*/RADIX = 16/' Makefile
sed -i 's/.*prime =.*/prime = 503/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 512/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 32/' Makefile
sed -i 's/.*prime =.*/prime = 503/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 512/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 64/' Makefile
sed -i 's/.*prime =.*/prime = 503/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 512/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 24/' Makefile
sed -i 's/.*prime =.*/prime = 503/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 528/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 34/' Makefile
sed -i 's/.*prime =.*/prime = 503/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 510/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 51/' Makefile
sed -i 's/.*prime =.*/prime = 503/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 510/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

################################################
sed -i 's/.*RADIX =.*/RADIX = 16/' Makefile
sed -i 's/.*prime =.*/prime = 610/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 640/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 32/' Makefile
sed -i 's/.*prime =.*/prime = 610/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 640/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 64/' Makefile
sed -i 's/.*prime =.*/prime = 610/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 640/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 128/' Makefile
sed -i 's/.*prime =.*/prime = 610/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 640/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 24/' Makefile
sed -i 's/.*prime =.*/prime = 610/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 624/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------



sed -i 's/.*RADIX =.*/RADIX = 34/' Makefile
sed -i 's/.*prime =.*/prime = 610/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 646/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------



sed -i 's/.*RADIX =.*/RADIX = 51/' Makefile
sed -i 's/.*prime =.*/prime = 610/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 663/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------


################################################
sed -i 's/.*RADIX =.*/RADIX = 16/' Makefile
sed -i 's/.*prime =.*/prime = 751/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 768/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 32/' Makefile
sed -i 's/.*prime =.*/prime = 751/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 768/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 64/' Makefile
sed -i 's/.*prime =.*/prime = 751/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 768/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 24/' Makefile
sed -i 's/.*prime =.*/prime = 751/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 768/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 34/' Makefile
sed -i 's/.*prime =.*/prime = 751/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 782/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

sed -i 's/.*RADIX =.*/RADIX = 51/' Makefile
sed -i 's/.*prime =.*/prime = 751/' Makefile
sed -i 's/.*prime_round =.*/prime_round = 765/' Makefile 
#------------------------------------
for i in {1..1}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
#------------------------------------

 

echo "bacth synthesis finished!"