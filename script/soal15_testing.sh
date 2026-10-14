#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# TESTING SOAL NOMOR 15: Weighted Round Robin Testing (40 Requests)

echo "TESTING SOAL 15: Uji Distribusi Beban Weighted Round Robin (3:1)"
echo "Mengirimkan 40 request secara berurutan ke geto (10.93.4.2)..."

for i in $(seq 1 40); do
    curl -s http://10.93.4.2/ | grep -o '"worker":"[^"]*"' | cut -d '"' -f 4
done | sort | uniq -c

echo -e "\nTarget Distribusi yang Diharapkan (Rasio 3:1):"
echo "  30 nanami (75%)"
echo "  10 todo   (25%)"
