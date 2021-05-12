runtime_base_address=$(readelf -l $2 | grep LOAD | grep "R E" | awk "{print \$3}")
elf_offset=$(strings -a -t x $2 | grep $1 | awk '{print "0x"$1}')
runtime_offset=$((runtime_base_address + elf_offset))

echo "ELF OFFSET = $((elf_offset))"
echo "Runtime OFFSET = $runtime_offset"
