#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# TESTING SOAL NOMOR 12: CNAME, PTR, & DNS FORWARDER

echo "TESTING SOAL 12: KLIEN $(hostname) (CNAME, PTR, & DNS FORWARDER)"

# Pastikan bind-tools terpasang
if ! command -v dig &>/dev/null; then
    apk add --no-cache bind-tools 2>/dev/null || apt-get install -y dnsutils 2>/dev/null
fi

echo -e "\n[1] Pengujian CNAME www.jujutsu.k59.com:"
dig @10.93.1.2 www.jujutsu.k59.com +noall +answer

echo -e "\n[2] Pengujian Reverse DNS (PTR) untuk IP 10.93.1.4 (gojo):"
dig @10.93.1.2 -x 10.93.1.4 +noall +answer

echo -e "\n[3] Pengujian DNS Forwarder ke Internet via DNS Master (google.com):"
dig @10.93.1.2 google.com +short

echo -e "\n[4] Pengujian Ping ke Domain Internet (google.com):"
echo "nameserver 10.93.1.2" > /etc/resolv.conf
ping -c 3 google.com
