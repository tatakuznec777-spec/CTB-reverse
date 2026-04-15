import sys

def xor(data: bytes, key: bytes) -> bytes:
    return bytes([d ^ key[i % len(key)] for i, d in enumerate(data)])

def auto_xor(cipher_hex: str, known_prefix: str = "flag{"):
    c = bytes.fromhex(cipher_hex)
    k = bytes([c[i] ^ ord(known_prefix[i]) for i in range(len(known_prefix))])
    plain = xor(c, k)
    print(f"🔑 Ключ (первые {len(k)} байт): {k.hex()}")
    print(f"📜 Декод: {plain[:50]}...")
    return plain

if __name__ == "__main__":
    if len(sys.argv) > 1:
        auto_xor(sys.argv[1])
    else:
        print("Использование: python3 solve_xor.py 'hex_data' [known_prefix]")