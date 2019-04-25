# Firmware dumps

- HT802 1.0.0.24 extracted via serial
- HT802 1.0.10.6 extraced via gssu ftp

# Grandstream Super User
- Connect to ssh and login with admin account
- Run command `gssu`
- Copy the challenge
- Run `python3 GSSU.py ADMIN_PASSWORD CHALLENGE` on your pc
- Copy the response and paste it in the ssh shell
- Enjoy your root shell ;-)

Example:
```
$ ssh admin@192.168.1.100
Grandstream HT802 Command Shell Copyright 2006-2018
admin@192.168.1.100's password: 
GS> gssu
Challenge: b319d6c803a2f142
Response: 
# uname -a
Linux HT8XX 3.4.20-rt31-dvf-v1.2.6.1-rc2 #27 PREEMPT Mon Aug 20 15:19:59 CST 2018 armv5tejl GNU/Linux
# ls
app              dev              oem_profile      tmp
bin              etc              proc             usr
conf             lang             sbin             var
core             lib              sys
country_profile  oem              test
# 
```
# Firmware format
## Header (648 bytes)
| Size (byte)  | Type | Name | Description |
| :----------: | ---- | ---- | ------- |
| 4 | Unsigned LE Int | Magic | 0x23C97AF9 |
| 64 | Char string | File name 1 | ht802boot.bin |
| 64 | Char string | File name 2 | ht802core.bin |
| 64 | Char string | File name 3 | ht802base.bin |
| 64 | Char string | File name 4 | ht802prog.bin |
| 64 | Char string | File name 5 | empty |
| 64 | Char string | File name 6 | empty |
| 64 | Char string | File name 7 | empty |
| 4 | Unsigned LE Int | File size 1 | length in bytes |
| 4 | Unsigned LE Int | File size 2 | length in bytes |
| 4 | Unsigned LE Int | File size 3 | length in bytes |
| 4 | Unsigned LE Int | File size 4 | length in bytes |
| 4 | Unsigned LE Int | File size 5 | length in bytes |
| 4 | Unsigned LE Int | File size 6 | length in bytes |
| 4 | Unsigned LE Int | File size 7 | length in bytes |
| 4 | Unsigned LE Int | File version 1 | 0x01000a02 --> 1.0.10.2 |
| 4 | Unsigned LE Int | File version 2 | 0x01000a02 --> 1.0.10.2 |
| 4 | Unsigned LE Int | File version 3 | 0x01000a06 --> 1.0.10.6 |
| 4 | Unsigned LE Int | File version 4 | 0x01000a07 --> 1.0.10.6 |
| 4 | Unsigned LE Int | File version 5 | empty |
| 4 | Unsigned LE Int | File version 6 | empty |
| 4 | Unsigned LE Int | File version 7 | empty |
| 4 | Unsigned LE Int | File mask 1 | 0x00000000 |
| 4 | Unsigned LE Int | File mask 2 | 0x00070000 |
| 4 | Unsigned LE Int | File mask 3 | 0x00000001 |
| 4 | Unsigned LE Int | File mask 4 | 0x00000000 |
| 4 | Unsigned LE Int | File mask 5 | 0x00000000 |
| 4 | Unsigned LE Int | File mask 6 | 0x00000000 |
| 4 | Unsigned LE Int | File mask 7 | 0x00000000 |
| 112 | Byte array | Unknown | All zeros |

## Body
| Size (byte)  | Type | Name | Description |
| :----------: | ---- | ---- | ------- |
| File size 1 | Byte array | File 1 | Encrypted (header + body) (ht802boot.bin, uboot)|
| File size 2 | Byte array | File 2 | Encrypted (header + body) (ht802core.bin, linux kernel)|
| File size 3 | Byte array | File 3 | Encrypted (header + body) (ht802base.bin, squashfs)|
| File size 4 | Byte array | File 4 | Encrypted (header + body) (ht802prog.bin, squashfs)|
| File size 5 | Byte array | File 5 | Encrypted (header + body) |
| File size 6 | Byte array | File 6 | Encrypted (header + body) |
| File size 7 | Byte array | File 7 | Encrypted (header + body) |

# File format
| Size (byte)  | Type | Name | Description |
| :----------: | ---- | ---- | ------- |
| 512 | Byte array | Header | Encrypted only first 32 bytes |
| File size - 512 | Byte array | File | Encrypted (by block of 32 bytes each time reinitializing the cipher) |

# File encryption
Each file is encrypted with AES 128 CBC  
The default key is: 37d6ae8bc920374649426438bde35493 (16 bytes)  
The IV is: Grandstream Inc. (16 bytes)  
Only the first 32 bytes of the header are encrypted  
All the body is encrypted by block of 32 bytes, each time reinitializing the cipher (LOL)  

I'm pretty sure of these infos, but I'm still unable to decrypt the files with my script  
Maybe this is due to the wrong conversion of the key from hex to bytes they made.  
They always subtract 0x37 from hex 'A'-'F', also if they are lowercase, so 'a'-'f' will become 0x2a...0x2f instead of 0xa...0xf  
Infact, if you try to decrypt the files using the default key but uppercase, the decryption will fail!  
