################################################ 

for i in {1..100}
do
	################################################ 
	echo "Test # $i:\n"
	sed -i 's/.*cmd =.*/cmd = 1/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 0/' Makefile
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 2/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 0/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 3/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 0/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 4/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 0/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 5/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 0/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 1/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 1/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 2/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 1/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 3/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 1/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 4/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 1/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
	################################################ 
	sed -i 's/.*cmd =.*/cmd = 5/' Makefile
	sed -i 's/.*extension_field =.*/extension_field = 1/' Makefile
	echo "Test # $i:\n"
	make clean; make || exit 1 ;
done
   
 