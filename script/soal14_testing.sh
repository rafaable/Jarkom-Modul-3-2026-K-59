#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# TESTING SOAL NOMOR 14: Access Control Testing (Client vs Proxy)

echo "TESTING SOAL 14: KLIEN $(hostname) (Uji Akses Langsung ke Worker)"

echo -e "\n[1] Akses Langsung ke Frontend Worker maki (10.93.4.3):"
curl -I http://10.93.4.3/ 2>&1 | head -n 5

echo -e "\n[2] Akses Langsung ke Frontend Worker panda (10.93.4.4):"
curl -I http://10.93.4.4/ 2>&1 | head -n 5

echo -e "\n[3] Akses Langsung ke API Worker nanami (10.93.4.5):"
curl -I http://10.93.4.5/ 2>&1 | head -n 5

echo -e "\n[4] Akses Langsung ke API Worker todo (10.93.4.6):"
curl -I http://10.93.4.6/ 2>&1 | head -n 5

echo -e "\n[5] Akses Langsung ke API Worker kirara (10.93.4.7):"
curl -I http://10.93.4.7/ 2>&1 | head -n 5
