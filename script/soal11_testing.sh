#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# TESTING SOAL NOMOR 11

TARGET="${1:-$(hostname)}"

test_utahime() {
    echo "TESTING SOAL 11: NODE utahime (DNS Master)"

    echo -e "\n[1] Pengecekan Sintaks named-checkconf:"
    named-checkconf && echo "named-checkconf OK"

    echo -e "\n[2] Pengecekan Zona named-checkzone:"
    named-checkzone jujutsu.k59.com /etc/bind/jujutsu/db.jujutsu.k59.com

    echo -e "\n[3] Status Layanan BIND9:"
    service named status 2>/dev/null || service bind9 status

    echo -e "\n[4] Query Dig Lokal ke Master (10.93.1.2):"
    dig @10.93.1.2 jujutsu.k59.com +short
    dig @10.93.1.2 jujutsu.k59.com SOA +noall +answer
}

test_shoko() {
    echo "TESTING SOAL 11: NODE shoko (DNS Slave)"

    echo -e "\n[1] Status Layanan BIND9:"
    service named status 2>/dev/null || service bind9 status

    echo -e "\n[2] Verifikasi File Replikasi Zona dari Master:"
    if [ -f /var/cache/bind/db.jujutsu.k59.com ]; then
        echo "File zona berhasil disinkronisasi ke /var/cache/bind/db.jujutsu.k59.com"
        ls -l /var/cache/bind/db.jujutsu.k59.com
    else
        echo "File zona belum ditemukan, memeriksa log zone transfer..."
    fi

    echo -e "\n[3] Query SOA ke Slave (Verifikasi Serial Tersinkronisasi):"
    dig @10.93.1.3 jujutsu.k59.com SOA +noall +answer

    echo -e "\n[4] Query A Record ke Slave (10.93.1.3):"
    dig @10.93.1.3 jujutsu.k59.com +short
}

test_client() {
    echo "TESTING SOAL 11: KLIEN $(hostname) (Uji Resolusi Domain & Replikasi)"

    if ! command -v dig &>/dev/null; then
        echo "Mengunduh paket bind-tools..."
        apk add --no-cache bind-tools 2>/dev/null || apt-get install -y dnsutils 2>/dev/null
    fi

    echo -e "\n[1] Query Dig Lengkap ke DNS Master utahime (10.93.1.2):"
    dig @10.93.1.2 jujutsu.k59.com

    echo -e "\n[2] Query Dig Lengkap ke DNS Slave shoko (10.93.1.3):"
    dig @10.93.1.3 jujutsu.k59.com

    echo -e "\n[3] Perbandingan Nomor Serial SOA (Master vs Slave):"
    MASTER_SERIAL=$(dig @10.93.1.2 jujutsu.k59.com SOA +short | awk '{print $3}')
    SLAVE_SERIAL=$(dig @10.93.1.3 jujutsu.k59.com SOA +short | awk '{print $3}')
    echo "Nomor Serial pada Master (utahime): $MASTER_SERIAL"
    echo "Nomor Serial pada Slave  (shoko)  : $SLAVE_SERIAL"

    if [ -n "$MASTER_SERIAL" ] && [ "$MASTER_SERIAL" = "$SLAVE_SERIAL" ]; then
        echo "Status: SINKRON SEMPURNA (Kedua server memiliki nomor serial identik)"
    else
        echo "Status: BELUM SINKRON (Menunggu transfer zona selesai)"
    fi
}

case "$TARGET" in
    utahime)
        test_utahime
        ;;
    shoko)
        test_shoko
        ;;
    *)
        test_client
        ;;
esac
