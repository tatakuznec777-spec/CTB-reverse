from scapy.all import *
import os, sys

def extract_http_files(pcap):
    packets = rdpcap(pcap)
    os.makedirs("extracted_http", exist_ok=True)
    http_data = b""
    for pkt in packets:
        if pkt.haslayer(TCP) and pkt.haslayer(Raw):
            payload = pkt[Raw].load
            if b"HTTP/" in payload:
                http_data += payload
    # Сохраняем сырой HTTP для binwalk
    with open("extracted_http/raw_http.bin", "wb") as f: f.write(http_data)
    print("✅ HTTP payload сохранён. Запусти: binwalk -Me extracted_http/raw_http.bin")

def extract_dns_txt(pcap):
    packets = rdpcap(pcap)
    for pkt in packets:
        if pkt.haslayer(DNSQR) and pkt[DNSQR].qtype == 16:
            if pkt.haslayer(DNSRR) and pkt[DNSRR].rdata:
                print(f"📦 DNS TXT: {pkt[DNSRR].rdata}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        extract_http_files(sys.argv[1])
        extract_dns_txt(sys.argv[1])
    else:
        print("Использование: python3 solve_pcap.py capture.pcap")