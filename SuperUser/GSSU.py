#!/usr/bin/env python3

# Grandstream Super User by BigNerd95

import hashlib, sys, binascii

def gsresponse(password, challenge):
    key = challenge+":GrandstreamTX2013lZpRsFzCbM:"+password
    res = hashlib.md5(key.encode('ascii')).digest()[:8]
    return binascii.hexlify(res).decode("ascii")

def gsresponsev2(password, challenge):
    key = "grAndSTreamTX20hT818V2FzC2M0AINT:"+challenge+":"+password+"\n"
    res = hashlib.sha256(key.encode('ascii')).digest()
    return binascii.hexlify(res).decode("ascii")[16:16+32]

if __name__ == "__main__":
    print("Grandstream Super User by BigNerd95\n")
    if len(sys.argv) == 3:
        password = sys.argv[1]
        challenge = sys.argv[2]
        response = gsresponse(password, challenge)
        print("Response: " + response)
        responsev2 = gsresponsev2(password, challenge)
        print("Response HT8XXV2: " + responsev2)
    else:
        print("Usage: " + sys.argv[0] + " ADMIN_PASSWORD CHALLENGE")
        print("\nLogin via ssh in Grandstream device")
        print("Run command: gssu")
    print("")

