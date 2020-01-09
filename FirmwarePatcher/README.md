# GrandStream Firmware Patcher
A tool to extract, decrypt and patch [firmware](http://www.grandstream.com/support/firmware)  

With this tool you can create Custom Firmware for Grandstream devices  

## Usage
### Info
```bash
$ ./GSFW.py info -i ht802fw.bin
** Firmware Info **
Contained files:
	 ht802boot.bin 	version: 1.0.9.1 	size: 245760 bytes
	 ht802core.bin 	version: 1.0.9.1 	size: 1187840 bytes
	 ht802base.bin 	version: 1.0.9.2 	size: 2838528 bytes
	 ht802prog.bin 	version: 1.0.9.3 	size: 3223552 bytes
```  

### Extract 
Decrypt and extract all contained files
```bash
$ ./GSFW.py extract -i ht802fw.bin -d /tmp/test -k 37d6ae8bc920374649426438bde35493
** Firmware Extract **
Used key: 37d6ae8bc920374649426438bde35493
Extracting files:
	 /tmp/test/ht802boot.bin 	version: 1.0.9.1 	size: 245760 bytes
		Head key: 738d0cb8bc02736494244683fb5e4539
		Body key: 000b06d307e2041a0a0bfd2100010000
		Decrypting...
	 /tmp/test/ht802core.bin 	version: 1.0.9.1 	size: 1187840 bytes
		Head key: 738d0cb8bc02736494244683fb5e4539
		Body key: 000c834507e2041a0a0bfd2100010000
		Decrypting...
	 /tmp/test/ht802base.bin 	version: 1.0.9.2 	size: 2838528 bytes
		Head key: 738d0cb8bc02736494244683fb5e4539
		Body key: 000d64c807e2041a0a0bfd2100010000
		Decrypting...
	 /tmp/test/ht802prog.bin 	version: 1.0.9.3 	size: 3223552 bytes
		Head key: 738d0cb8bc02736494244683fb5e4539
		Body key: 000ee4a507e2041a0a0bfd2100010000
		Decrypting...
```  
You can now extract filesystem from sqfs:  
`$ sudo binwalk -e /tmp/test/ht802prog.bin`  
Make you mods...  
And repack the sqfs:  
`$ sudo mksquashfs squashfs-root progmod.squashfs -comp xz -all-root -noappend -always-use-fragments `

### Patch  
Replace the body of a modified file (eg: modified prog squashfs)  
```bash
./GSFW.py patch -i ht802fw.bin -o ht802fw.bin.mod -n ht802prog.bin -b progmod.squashfs -v 1.0.9.4 -k 37d6ae8bc920374649426438bde35493
** Firmware Patch **
Used key: 37d6ae8bc920374649426438bde35493
Looking for file: ht802prog.bin
	File found!
	Decrypting file header:
		Head key: 738d0cb8bc02736494244683fb5e4539
		Body key: 000ee4a507e2041a0a0bfd2100010000
		Decrypting...
	New version:   1.0.9.4
	New file size: 3223552 bytes
	New checksum:  0xe4a5
	Patching file header...
	Encrypting new file:
		Head key: 738d0cb8bc02736494244683fb5e4539
		Body key: 000ee4a507e2041a0a0bfd2100010000
		Encrypting...
Patching firmware header...
Writing new firmware
```  
