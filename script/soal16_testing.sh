#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# TESTING SOAL NOMOR 16: Path-Based Routing Testing

echo "TESTING SOAL 16: KLIEN $(hostname) (Uji Path-Based Routing)"

# Pastikan nameserver mengarah ke DNS Master (utahime)
echo "nameserver 10.93.1.2" > /etc/resolv.conf

echo -e "\n[1] Akses Web Utama Root (/) - Target: maki / panda bergantian:"
for i in {1..4}; do
    echo -n "Request $i: "
    curl -s http://jujutsu.k59.com/
done

echo -e "\n[2] Akses Endpoint API (/api) - Target: nanami / todo via geto:"
for i in {1..4}; do
    echo -n "Request $i: "
    curl -s http://jujutsu.k59.com/api | grep -o '"worker":"[^"]*"'
done
