#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 12: CNAME, Reverse DNS (PTR), & DNS Forwarder

TARGET="${1:-utahime}"

setup_utahime() {
    echo "[utahime] Mengonfigurasi CNAME, Reverse DNS PTR, dan DNS Forwarder..."

    # 1. Konfigurasi named.conf.options dengan DNS Forwarder ke gateway internet
    cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    auth-nxdomain no;
    listen-on { any; };
    listen-on-v6 { none; };
    allow-query { any; };
    dnssec-validation no;

    // DNS Forwarder ke IP gateway NAT internet
    forwarders {
        192.168.122.1;
    };
};
EOF

    # 2. Perbarui named.conf.local untuk menambahkan Zona Reverse PTR
    cat << 'EOF' > /etc/bind/named.conf.local
// Zona Forward jujutsu.k59.com
zone "jujutsu.k59.com" {
    type master;
    file "/etc/bind/jujutsu/db.jujutsu.k59.com";
    allow-transfer { 10.93.1.3; };
    also-notify { 10.93.1.3; };
};

// Zona Reverse untuk subnet 10.93.1.0/24 (DMZ)
zone "1.93.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/db.1.93.10.in-addr.arpa";
    allow-transfer { 10.93.1.3; };
    also-notify { 10.93.1.3; };
};
EOF

    # 3. Perbarui Zona Forward: Tambahkan A Record gojo dan CNAME www
    cat << 'EOF' > /etc/bind/jujutsu/db.jujutsu.k59.com
;
; BIND data file for jujutsu.k59.com
;
$TTL    604800
@       IN      SOA     utahime.jujutsu.k59.com. root.jujutsu.k59.com. (
                              2026101403 ; Serial
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

; Domain Utama (mengarah ke gojo - Public Reverse Proxy)
@       IN      A       10.93.1.4
gojo    IN      A       10.93.1.4

; CNAME www merujuk ke domain utama jujutsu.k59.com
www     IN      CNAME   jujutsu.k59.com.
EOF

    # 4. Buat File Database Zona Reverse DNS (PTR)
    cat << 'EOF' > /etc/bind/jujutsu/db.1.93.10.in-addr.arpa
;
; BIND reverse data file for 10.93.1.0/24
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

; PTR Record: 10.93.1.4 -> jujutsu.k59.com
4       IN      PTR     jujutsu.k59.com.
EOF

    # 5. Validasi konfigurasi sintaks dan zona
    named-checkconf
    named-checkzone jujutsu.k59.com /etc/bind/jujutsu/db.jujutsu.k59.com
    named-checkzone 1.93.10.in-addr.arpa /etc/bind/jujutsu/db.1.93.10.in-addr.arpa

    # 6. Reload layanan BIND9
    rndc reload || service named restart || service bind9 restart
    service named status || service bind9 status
}

setup_shoko() {
    echo "[shoko] Mengonfigurasi DNS Slave Reverse Zone & Forwarder..."

    # 1. Konfigurasi named.conf.options dengan DNS Forwarder ke gateway internet
    cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    auth-nxdomain no;
    listen-on { any; };
    listen-on-v6 { none; };
    allow-query { any; };
    dnssec-validation no;

    forwarders {
        192.168.122.1;
    };
};
EOF

    # 2. Konfigurasi named.conf.local (Zona Slave Forward & Reverse)
    cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k59.com" {
    type slave;
    file "/var/cache/bind/db.jujutsu.k59.com";
    masters { 10.93.1.2; };
};

zone "1.93.10.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.1.93.10.in-addr.arpa";
    masters { 10.93.1.2; };
};
EOF

    # 3. Validasi konfigurasi
    named-checkconf

    # 4. Reload layanan BIND9
    rndc reload || service named restart || service bind9 restart
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
