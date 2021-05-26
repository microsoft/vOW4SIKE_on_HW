################################################ 

for i in {1..100}
do
   echo "Test # $i:\n"
   make clean; make || exit 1 ;
done
