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
    res = bytes()
    for i in range(0, len(buffer), 32):
        cipher = AES.new(key, AES.MODE_CBC, GS_IV)
        if encrypt:
            res += cipher.encrypt(buffer[i:i+32])
        else:
            res += cipher.decrypt(buffer[i:i+32])
    return res

def GSencrypt(key, buffer):
    return GSencryptDecrypt(key, buffer, True)

def GSdecrypt(key, buffer):
    return GSencryptDecrypt(key, buffer, False)

def create_write_file(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)

def parseHeader(header):
    infos = struct.unpack("<I" + "64s" * GS_NUM_FILES + "I" * GS_NUM_FILES + "I" * GS_NUM_FILES, header[ : 4 + 64 * GS_NUM_FILES + 4 * GS_NUM_FILES + 4 * GS_NUM_FILES])
    magic = infos[0]
    filenames = list(map(lambda x : str(x, "ascii").rstrip("\0"), infos[1:1+GS_NUM_FILES]))
    filesizes = infos[1+GS_NUM_FILES:1+GS_NUM_FILES*2]
    filevers  = list(map(lambda x : socket.inet_ntoa(struct.pack(">I", x)), infos[1+GS_NUM_FILES*2:1+GS_NUM_FILES*3]))

    return magic, filenames, filesizes, filevers

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
    print("Used key:", key)

    key = GrandStupidity(key)
    print("Head key:", key)

    header = input_data[:512]
    header_enc32 = GSencrypt(bytes.fromhex(key), header[:32])

    body_key = swapBytes(header[16:32])
    print("Body key:", binascii.hexlify(body_key).decode("ascii"))
    
    body_enc = GSencrypt(body_key, input_data[512:])

    return header_enc32 + header[32:] + body_enc


#########################################################

def info(input_file):
    print('** Firmware Info **')

    magic, filenames, filesizes, filevers = parseHeader(input_file.read(648))

    if magic != GS_MAGIC:
        print("Invalid magic!")
        return
    
    print("Contained files:")
    
    for name, ver, size in zip(filenames, filevers, filesizes):
        if name:
            print("\t", name, "\tversion:", ver, "\tsize:", size, "bytes")

    input_file.close()

def extract(input_file, output_dir, key):
    print('** Firmware Extract **')
    
    output_dir = os.path.join(output_dir, '')
    if os.path.exists(output_dir):
        print("Directory", os.path.basename(output_dir) , "already exists, cannot extract!")
        return

    magic, filenames, filesizes, filevers = parseHeader(input_file.read(648))

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
                create_write_file(output_dir + name, plain_data)

    input_file.close()

def patch(orifinal, output, name, body, key):
    print("Coming soon")

def parse_cli():
    parser = ArgumentParser(description='** GrandStream Firmware Patcher by BigNerd95 **')
    subparser = parser.add_subparsers(dest='subparser_name')

    infoParser = subparser.add_parser('info', help='Firmware info')
    infoParser.add_argument('-i', '--input', required=True, metavar='INPUT_FILE', type=FileType('rb'))

    extractParser = subparser.add_parser('extract', help='Extract and decrypt files')
    extractParser.add_argument('-i', '--input', required=True, metavar='INPUT_FILE', type=FileType('rb'))
    extractParser.add_argument('-d', '--directory', required=True, metavar='EXTRACT_DIRECTORY')
    extractParser.add_argument('-k', '--key', metavar='KEY', default=GS_KEY, type=valid_key, help='32 bytes hex string, Default: '+GS_KEY)

    patchParser = subparser.add_parser('patch', help='Patch original firmware')
    patchParser.add_argument('-i', '--input', required=True, metavar='INPUT_FILE', type=FileType('rb'), help='Original firmware file')
    patchParser.add_argument('-o', '--output', required=True, metavar='OUTPUT_FILE', type=FileType('wb'), help='Output patched firmware')
    patchParser.add_argument('-n', '--name', required=True, metavar='FILE_TO_PATCH', help='File name to patch')
    patchParser.add_argument('-b', '--body', required=True, metavar='INPUT_BODY', type=FileType('rb'), help='Body of file to patch')
    patchParser.add_argument('-k', '--key', metavar='KEY', default=GS_KEY, type=valid_key, help='32 bytes hex string, Default: '+GS_KEY)

    if len(sys.argv) < 2:
        parser.print_help()

    return parser.parse_args()

def main():
    args = parse_cli()
    if args.subparser_name == 'info':
        info(args.input)
    elif args.subparser_name == 'extract':
        extract(args.input, args.directory, args.key)
    elif args.subparser_name == 'patch':
        patch(args.input, args.output, args.name, args.body, args.key)


if __name__ == '__main__':
    main()
