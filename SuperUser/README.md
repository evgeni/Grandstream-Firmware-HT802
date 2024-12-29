# GrandStream Super User

## HT802 and similar

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

## HT802V2 and similar

- Connect as `root` via SSH. (Only works if you've sneaked in your key into `/.ssh/authorized_keys` somehow!)
- Dropbear will automatically launch `gssu` for `root`
- Copy the challenge and the PN
- Run `python3 GSSU.py PN CHALLENGE`
- Copy the response and paste it in the ssh shell
- Enjoy your root shell ;-)

Example:
```
% ./GSSU.py 9610001234A e00288708f0597ae1ebb169ad3e9cc53
Grandstream Super User by BigNerd95

Response: 97af1fd5a3f3ab48
Response HT8XXV2: 8326356c77596b780cb0342d6d4b32db

% ssh root@192.168.1.100
PN: 9610001234A
Challenge: e00288708f0597ae1ebb169ad3e9cc53
Response:
/ # uname -a
Linux HT8XXV2 4.4.143 #108 SMP PREEMPT Mon May 13 18:12:49 CST 2024 armv7l GNU/Linux
```

# Direct root shell (run time patch)
You can patch dropbear at run time to always spawn a root shell directly, so you don't have to use GSSU.py all the time   
(If you reboot the device the patch will be lost)  
1) Get dropbear binary on your PC  
- From firmware image  
  - Download the same firmware version installed on your device from Grandstream website  
  - Decrypt the firmware using FirmwarePatcher `./GSFW.py extract -i ht802fw.bin -d ext`  
  - Unpack ht802base.bin using binwalk `sudo binwalk -e ht802base.bin`  
  - You can find dropbear inside `_ht802base.bin.extracted/squashfs-root/usr/sbin/`  
- From device  
  - On device: `nc -l -p 1234 < /usr/sbin/dropbear`  
  - On PC: `nc 192.168.2.235 1234 > dropbear` (ctrl+c after 10 seconds to close the connection)  

2) Find the offset of "gs_config -ssh" inside dropbear binary  
- On PC run `./offset_finder.sh "gs_config -ssh" dropbear`  
- Output example
```
ELF OFFSET = 244948
Runtime OFFSET = 277716
```

3) Patch dropbear  
- Replace `OFFSET` in the script below with the `Runtime OFFSET` output of `offset_finder.sh` command  
- On device run (copy paste)  
```bash
string_offset=OFFSET #(Runtime OFFSET output of offset_finder.sh command)
for pid in $(pidof dropbear)
do
    echo -e -n "/bin/sh\x00" | dd of=/proc/$pid/mem bs=1 seek=$string_offset 2>/dev/null
done


```
- Now you can try to logout from ssh and login again, a root shell should be spawned directly  
