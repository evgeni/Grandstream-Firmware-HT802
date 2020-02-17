# Debug

## On Grandstream device
```bash
$ cd /tmp
$ wget https://github.com/BigNerd95/Grandstream-Firmware-HT802/raw/master/Debug/gdbserver-armel-static-8.0.1 --no-check-certificate
$ chmod 777 gdbserver-armel-static-8.0.1
$ gdbserver-armel-static-8.0.1 host:5050 --attach $(pidof gs_ata)
```

## On your PC  
```bash
$ gdb-multiarch
$ target remote 192.168.1.2:5050  # replace 192.168.1.2 with the ip of your grandstream device
$ break *0x34b0c
$ c
$ s
```

## GrandStream debugger  
If you set nvram `gdb_debug_server` variable and setup a tftp server, the device will automatically run gs_ata with debug support.  
Look inside [/app/bin/ht_start.sh](https://github.com/BigNerd95/Grandstream-Firmware-HT802/blob/master/FirmwareDumps/HT802-1.0.10.6/app/bin/ht_start.sh#L55) for more info.  
