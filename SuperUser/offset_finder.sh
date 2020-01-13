base_address=$(readelf -l $2 | grep LOAD | grep "R E" | awk "{print \$3}")

string_elf_offset=$(strings -a -t x $2 | grep $1 | awk '{print "0x"$1}')

string_offset=$((base_address + string_elf_offset))

echo "OFFSET = $string_offset"
