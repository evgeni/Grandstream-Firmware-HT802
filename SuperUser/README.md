# GrandStream Super User
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
