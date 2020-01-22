#!/usr/bin/env python3

# GrandStream Firmware Patcher by BigNerd95

import struct, binascii, hashlib, sys, os, socket
from Crypto.Cipher import AES
from argparse import ArgumentParser, FileType, ArgumentTypeError

GS_IV = b"Grandstream Inc."
GS_KEY = "37d6ae8bc920374649426438bde35493"
GS_NUM_FILES = 7
GS_MAGIC = 0x23c97af9

def GrandStupidity(key):
    res = bytearray(key.encode("ascii"))

    # swap pairs (swap nibbles of header key)
    for i in range(0, len(res), 2):
        res[i], res[i+1] = res[i+1], res[i]

    # stupid programmer @ GrandStream who doesn't know how to convert from hex to bytes
    for i in range(0, len(res), 4):
        if res[i+1] >= ord('a'):
            res[i] = ord(format(int(chr(res[i]), 16) + 2 & 0xF, 'x'))

        if res[i+2] >= ord('a'):
            res[i+1] = ord(format(int(chr(res[i+1]), 16) + 2 & 0xF, 'x'))

        if res[i+3] >= ord('a'):
            res[i+2] = ord(format(int(chr(res[i+2]), 16) + 2 & 0xF, 'x'))

    return res.decode("ascii")

# swap pairs (swap bytes of body key)
def swapBytes(key):
    res = bytearray(key)
    for i in range(0, len(res), 2):
        res[i], res[i+1] = res[i+1], res[i]
    return bytes(res)

def GSencryptDecrypt(key, buffer, encrypt):
    res = bytearray(len(buffer))
    for i in range(0, len(buffer), 32):
        cipher = AES.new(key, AES.MODE_CBC, GS_IV)
        if encrypt:
            res[i:i+32] = cipher.encrypt(buffer[i:i+32])
        else:
            res[i:i+32] = cipher.decrypt(buffer[i:i+32])
    return res

def GSencrypt(key, buffer):
    return GSencryptDecrypt(key, buffer, True)

def GSdecrypt(key, buffer):
    return GSencryptDecrypt(key, buffer, False)

def create_write_file(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)

def parseHeaderFW(header):
    infos = struct.unpack("<I" + "64s" * GS_NUM_FILES + "I" * GS_NUM_FILES + "I" * GS_NUM_FILES, header[ : 4 + 64 * GS_NUM_FILES + 4 * GS_NUM_FILES + 4 * GS_NUM_FILES])
    magic = infos[0]
    filenames = list(map(lambda x : str(x, "ascii").rstrip("\0"), infos[1:1+GS_NUM_FILES]))
    filesizes = infos[1+GS_NUM_FILES:1+GS_NUM_FILES*2]
    filevers  = list(map(lambda x : socket.inet_ntoa(struct.pack(">I", x)), infos[1+GS_NUM_FILES*2:1+GS_NUM_FILES*3]))

    return magic, filenames, filesizes, filevers

def parseHeaderFile(header):
    keys = ["magic_file", "version_file", "size_max", "size_file", "image_id", "checksum_file", "ts_year", "ts_day", "ts_month", "ts_min", "ts_hour", "oem_id", "FV_V_Mask", "supp_bits_1", "supp_bits_2", "supp_bits_3", "supp_bits_4", "v1", "v2"]
    values = struct.unpack("<IIIIHHHBBBBHIHHHHII", header[:48])
    infos = dict(zip(keys, values))
    infos["version_file"] = socket.inet_ntoa(struct.pack(">I", infos["version_file"]))
    infos["v1"] = socket.inet_ntoa(struct.pack(">I", infos["v1"]))
    infos["v2"] = socket.inet_ntoa(struct.pack(">I", infos["v2"]))
    return infos

def patchHeaderFW(header, index, newversion, newsize):
    newhader = bytearray(header)
    newversion = struct.unpack(">I", socket.inet_aton(newversion))[0]
    newhader[4+64*GS_NUM_FILES+4*index:4+64*GS_NUM_FILES+4*index+4] = struct.pack("<I", newsize)
    newhader[4+64*GS_NUM_FILES+4*GS_NUM_FILES+4*index:4+64*GS_NUM_FILES+4*GS_NUM_FILES+4*index+4] = struct.pack("<I", newversion)
    return bytes(newhader)

def patchHeaderFile(header, newversion, newsize, newchecksum):
    newheader = bytearray(header)
    newversion = struct.unpack(">I", socket.inet_aton(newversion))[0]
    newheader[4:8] = struct.pack("<I", newversion)
    newheader[12:16] = struct.pack("<I", newsize)
    newheader[18:20] = struct.pack("<H", newchecksum)
    return bytes(newheader)

def valid_key(key):
    err = "Invalid key! You must pass a 32 bytes hex string"
    if len(key) != 32:
        raise ArgumentTypeError(err)
    try:
        int(key, 16)
        return key
    except ValueError:
        raise ArgumentTypeError(err)

def decrypt_file(input_data, key):

    key = GrandStupidity(key)
    print("\t\tHead key:", key)

    header = input_data[:512]
    header_plain32 = GSdecrypt(bytes.fromhex(key), header[:32])
    magic = struct.unpack("<I", header_plain32[:4])[0]

    if magic != GS_MAGIC:
        print("\t\tWrong key!")
        return

    body_key = swapBytes(header_plain32[16:32])
    print("\t\tBody key:", binascii.hexlify(body_key).decode("ascii"))
    
    print("\t\tDecrypting...")
    body_plain = GSdecrypt(body_key, input_data[512:])

    return header_plain32 + header[32:] + body_plain

def encrypt_file(input_data, key):

    key = GrandStupidity(key)
    print("\t\tHead key:", key)

    header = input_data[:512]
    header_enc32 = GSencrypt(bytes.fromhex(key), header[:32])

    body_key = swapBytes(header[16:32])
    print("\t\tBody key:", binascii.hexlify(body_key).decode("ascii"))
    
    print("\t\tEncrypting...")
    body_enc = GSencrypt(body_key, input_data[512:])

    return header_enc32 + header[32:] + body_enc

def computeChecksum(data):
    cksum = 0
    for i in range(0, len(data), 2):
        cksum += struct.unpack("<H", data[i:i+2])[0]
        cksum &= 0xffff
    return 0x10000-cksum

#########################################################

def info(input_file, verbose, key):
    print('** Firmware Info **')

    magic, filenames, filesizes, filevers = parseHeaderFW(input_file.read(648))

    if magic != GS_MAGIC:
        print("Invalid magic!")
        return

    if verbose:
        print("Used key:", key)
    
    print("Contained files:")
    
    for name, ver, size in zip(filenames, filevers, filesizes):
        if name:
            print("\t", name, "\tversion:", ver, "\tsize:", size, "bytes")
            
            if verbose:
                file_data = input_file.read(size)
                plain_data = decrypt_file(file_data, key)
                file_infos = parseHeaderFile(plain_data[:512])
                print("\t\tDate:", str(file_infos["ts_year"]) + "/" + str(file_infos["ts_month"]) + "/" + str(file_infos["ts_day"]) + " " + str(file_infos["ts_hour"]) + ":" + str(file_infos["ts_min"]))
                print("\t\tv1:", file_infos["v1"])
                print("\t\tv2:", file_infos["v2"])
                print("\t\tCorrect magic:   ", file_infos["magic_file"] == GS_MAGIC)
                print("\t\tCorrect version: ", file_infos["version_file"] == ver)
                print("\t\tCorrect size:    ", file_infos["size_file"] == size-512 and file_infos["size_file"] == len(plain_data[512:]))
                print("\t\tCorrect checksum:", file_infos["checksum_file"] == computeChecksum(plain_data[512:]))
                print("")

    input_file.close()

def extract(input_file, output_dir, key):
    print('** Firmware Extract **')
    
    output_dir = os.path.join(output_dir, '')
    if os.path.exists(output_dir):
        print("Directory", os.path.basename(output_dir) , "already exists, cannot extract!")
        return

    magic, filenames, filesizes, filevers = parseHeaderFW(input_file.read(648))

    if magic != GS_MAGIC:
        print("Invalid magic!")
        return
    
    print("Used key:", key)

    print("Extracting files:")
    
    for name, ver, size in zip(filenames, filevers, filesizes):
        if name:
            print("\t", output_dir + name, "\tversion:", ver, "\tsize:", size, "bytes")
            file_data = input_file.read(size)
            plain_data = decrypt_file(file_data, key)
            if plain_data:
                create_write_file(output_dir + name, plain_data[512:])
            print("")

    input_file.close()

def patch(original, output, mod_name, body, version, key):
    print('** Firmware Patch **')

    header_fw = original.read(648)

    magic, filenames, filesizes, filevers = parseHeaderFW(header_fw)

    if magic != GS_MAGIC:
        print("Invalid magic!")
        return
    
    print("Used key:", key)

    print("Looking for file:", mod_name)
    
    file_data = []
    file_name = []
    for name, ver, size in zip(filenames, filevers, filesizes):
        if name:
            file_name.append(name)
            if name == mod_name:
                newbody = body.read()
                checksum = computeChecksum(newbody)
                oldfile = original.read(size)

                print("\tFile found!")
                print("\tDecrypting file header:")
                plain_data = decrypt_file(oldfile[:512], key)
                infos = parseHeaderFile(plain_data)
                if len(newbody) > infos["size_max"]:
                    print("ERROR! File too big!")
                    print("Max allowed size:", infos["size_max"], "bytes")
                    return

                print("\tNew version:  ", version)
                print("\tNew file size:", len(newbody)+512, "bytes")
                print("\tNew checksum: ", hex(checksum))

                print("\tPatching file header...")
                new_header_file = patchHeaderFile(plain_data, version, len(newbody), checksum)
                
                print("\tEncrypting new file:")
                newfile = encrypt_file(new_header_file + newbody, key)

                file_data.append(newfile)
            else:
                file_data.append(original.read(size))

    print("Patching firmware header...")
    new_header_fw = patchHeaderFW(header_fw, file_name.index(mod_name), version, len(newfile))
    print("Writing new firmware")
    output.write(new_header_fw)
    for f in file_data:
        output.write(f)

    original.close()
    output.close()
    body.close()


def parse_cli():
    parser = ArgumentParser(description='** GrandStream Firmware Patcher by BigNerd95 **')
    subparser = parser.add_subparsers(dest='subparser_name')

    infoParser = subparser.add_parser('info', help='Firmware info')
    infoParser.add_argument('-i', '--input', required=True, metavar='INPUT_FILE', type=FileType('rb'))
    infoParser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    infoParser.add_argument('-k', '--key', metavar='KEY', default=GS_KEY, type=valid_key, help='32 bytes hex string, Default: '+GS_KEY)

    extractParser = subparser.add_parser('extract', help='Extract and decrypt files')
    extractParser.add_argument('-i', '--input', required=True, metavar='INPUT_FILE', type=FileType('rb'))
    extractParser.add_argument('-d', '--directory', required=True, metavar='EXTRACT_DIRECTORY')
    extractParser.add_argument('-k', '--key', metavar='KEY', default=GS_KEY, type=valid_key, help='32 bytes hex string, Default: '+GS_KEY)

    patchParser = subparser.add_parser('patch', help='Patch original firmware')
    patchParser.add_argument('-i', '--input', required=True, metavar='INPUT_FILE', type=FileType('rb'), help='Original firmware file')
    patchParser.add_argument('-o', '--output', required=True, metavar='OUTPUT_FILE', type=FileType('wb'), help='Output patched firmware')
    patchParser.add_argument('-n', '--name', required=True, metavar='FILE_TO_PATCH', help='File name to patch')
    patchParser.add_argument('-b', '--body', required=True, metavar='INPUT_BODY', type=FileType('rb'), help='Body of file to patch')
    patchParser.add_argument('-v', '--version', required=True, metavar='FILE_NEW_VERSION', help='New file version')
    patchParser.add_argument('-k', '--key', metavar='KEY', default=GS_KEY, type=valid_key, help='32 bytes hex string, Default: '+GS_KEY)

    if len(sys.argv) < 2:
        parser.print_help()

    return parser.parse_args()

def main():
    args = parse_cli()
    if args.subparser_name == 'info':
        info(args.input, args.verbose, args.key)
    elif args.subparser_name == 'extract':
        extract(args.input, args.directory, args.key)
    elif args.subparser_name == 'patch':
        patch(args.input, args.output, args.name, args.body, args.version, args.key)


if __name__ == '__main__':
    main()
