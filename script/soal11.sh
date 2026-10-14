#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 11: DNS Master (utahime) & DNS Slave (shoko) jujutsu.k59.com

TARGET="${1:-utahime}"

setup_utahime() {
    echo "[utahime] Mengonfigurasi DNS Master jujutsu.k59.com..."

    # 1. Atur IP statis utahime dan nameserver untuk instalasi paket
    ip addr flush dev eth0 2>/dev/null || true
    ip addr add 10.93.1.2/24 dev eth0
    ip link set eth0 up
    ip route replace default via 10.93.1.1 dev eth0 2>/dev/null || true
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # 2. Instalasi BIND9 dan dnsutils
    apt-get update -y
    apt-get install -y bind9 bind9utils bind9-doc dnsutils

    # 3. Konfigurasi named.conf.options
    cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    auth-nxdomain no;
    listen-on { any; };
    listen-on-v6 { none; };
    allow-query { any; };
    dnssec-validation no;
};
EOF

    # 4. Konfigurasi named.conf.local
    cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k59.com" {
    type master;
    file "/etc/bind/jujutsu/db.jujutsu.k59.com";
    allow-transfer { 10.93.1.3; };
    also-notify { 10.93.1.3; };
};
EOF

    # 5. Buat direktori dan file zona
    mkdir -p /etc/bind/jujutsu
    cat << 'EOF' > /etc/bind/jujutsu/db.jujutsu.k59.com
;
; BIND data file for jujutsu.k59.com
;
$TTL    604800
@       IN      SOA     utahime.jujutsu.k59.com. root.jujutsu.k59.com. (
                              2026101401 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.k59.com.
@       IN      NS      shoko.jujutsu.k59.com.

; A Record untuk Name Server
utahime IN      A       10.93.1.2
shoko   IN      A       10.93.1.3

; Domain Utama (mengarah ke reverse proxy gojo)
@       IN      A       10.93.1.4
EOF

    # 6. Validasi sintaks konfigurasi BIND9
    named-checkconf
    named-checkzone jujutsu.k59.com /etc/bind/jujutsu/db.jujutsu.k59.com

    # 7. Restart service BIND9
    service named restart || service bind9 restart
    service named status || service bind9 status
}

setup_shoko() {
    echo "[shoko] Mengonfigurasi DNS Slave jujutsu.k59.com..."

    # 1. Atur IP statis shoko dan nameserver untuk instalasi paket
    ip addr flush dev eth0 2>/dev/null || true
    ip addr add 10.93.1.3/24 dev eth0
    ip link set eth0 up
    ip route replace default via 10.93.1.1 dev eth0 2>/dev/null || true
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # 2. Instalasi BIND9 dan dnsutils
    apt-get update -y
    apt-get install -y bind9 bind9utils bind9-doc dnsutils

    # 3. Konfigurasi named.conf.options
    cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    auth-nxdomain no;
    listen-on { any; };
    listen-on-v6 { none; };
    allow-query { any; };
    dnssec-validation no;
};
EOF

    # 4. Konfigurasi named.conf.local
    cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k59.com" {
    type slave;
    file "/var/cache/bind/db.jujutsu.k59.com";
    masters { 10.93.1.2; };
};
EOF

    # 5. Validasi konfigurasi
    named-checkconf

    # 6. Restart service BIND9
    service named restart || service bind9 restart
    service named status || service bind9 status
}

case "$TARGET" in
    utahime)
        setup_utahime
        ;;
    shoko)
        setup_shoko
        ;;
    *)
        echo "Penggunaan: $0 {utahime|shoko}"
        exit 1
        ;;
esac
