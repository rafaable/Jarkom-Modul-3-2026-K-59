#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# PEMBUKTIAN REPLIKASI SOAL 11: MENAIKKAN SERIAL NUMBER PADA utahime

echo "UJI REPLIKASI SOAL 11: MENAIKKAN SERIAL NUMBER PADA utahime"

ZONE_FILE="/etc/bind/jujutsu/db.jujutsu.k59.com"

if [ ! -f "$ZONE_FILE" ]; then
    echo "Error: File zona $ZONE_FILE tidak ditemukan!"
    exit 1
fi

CURRENT_SERIAL=$(grep -oE '[0-9]{10}' "$ZONE_FILE" | head -n 1)

if [ -z "$CURRENT_SERIAL" ]; then
    echo "Error: Nomor serial 10 digit tidak ditemukan pada $ZONE_FILE"
    exit 1
fi

NEW_SERIAL=$((CURRENT_SERIAL + 1))

echo "Serial saat ini : $CURRENT_SERIAL"
echo "Menaikkan ke   : $NEW_SERIAL"

sed -i "s/$CURRENT_SERIAL/$NEW_SERIAL/" "$ZONE_FILE"

echo -e "\n[1] Validasi Zona Setelah Serial Dinaikkan:"
named-checkzone jujutsu.k59.com "$ZONE_FILE"

echo -e "\n[2] Reload BIND9 Master:"
rndc reload 2>/dev/null || service bind9 reload 2>/dev/null || service named reload 2>/dev/null

echo -e "\n[3] Verifikasi SOA Baru di Master (10.93.1.2):"
dig @10.93.1.2 jujutsu.k59.com SOA +noall +answer
