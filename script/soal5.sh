#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 5

TARGET="${1:-tengen}"

setup_tengen() {
    echo "[tengen] Mengonfigurasi Scope Network 3: Short Lease, Long Lease, DNS, & Search Domain"

    cat << 'EOCONF' > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

# 1. Definisi Class Network 2 (Divisi A) - Soal 4
class "pool1-dev" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}

class "pool2-support" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}

subclass "pool1-dev" 1:02:42:04:d1:3c:00; # itadori
subclass "pool1-dev" 1:02:42:8a:fc:d0:00; # fushiguro
subclass "pool2-support" 1:02:42:42:2e:33:00; # zenin
subclass "pool2-support" 1:02:42:86:56:6e:00; # okkotsu

# 2. Definisi Class Network 3 (Divisi B) - Soal 5
class "short-lease" {
    match pick-first-value (option dhcp-client-identifier, hardware);
    default-lease-time 1800;
    max-lease-time 1800;
}

class "long-lease" {
    match pick-first-value (option dhcp-client-identifier, hardware);
    default-lease-time 43200;
    max-lease-time 43200;
}

# Subclass Klien Network 3 berdasarkan MAC Address
# Tim Short Lease (ino & kusakabe)
subclass "short-lease" 1:02:42:d2:0f:95:00; # ino
subclass "short-lease" 1:02:42:e7:2e:22:00; # kusakabe

# Tim Long Lease (miwa)
subclass "long-lease" 1:f2:dd:ec:51:c9:cb;   # miwa

# Subnet lokal Network 4 (Data Center) - Tanpa pool dinamis
subnet 10.93.4.0 netmask 255.255.255.0 {
}

# Scope DHCP Network 2 (Divisi A)
subnet 10.93.2.0 netmask 255.255.255.0 {
    option routers 10.93.2.1;
    option broadcast-address 10.93.2.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;

    pool {
        allow members of "pool1-dev";
        range 10.93.2.10 10.93.2.35;
    }

    pool {
        allow members of "pool2-support";
        range 10.93.2.70 10.93.2.95;
    }
}

# Scope DHCP Network 3 (Divisi B) - Soal 5
subnet 10.93.3.0 netmask 255.255.255.0 {
    option routers 10.93.3.1;
    option broadcast-address 10.93.3.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;
    option domain-name "k59.com";
    option domain-search "k59.com";

    # Pool Short Lease: 1800 detik (30 menit) untuk ino dan kusakabe
    pool {
        allow members of "short-lease";
        range 10.93.3.10 10.93.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Pool Long Lease: 43200 detik (12 jam) untuk miwa
    pool {
        allow members of "long-lease";
        range 10.93.3.100 10.93.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}
EOCONF

    # Validasi sintaks dan restart service
    echo "Validasi sintaks dhcpd.conf:"
    dhcpd -t -cf /etc/dhcp/dhcpd.conf

    service isc-dhcp-server restart
    echo "Status layanan isc-dhcp-server:"
    service isc-dhcp-server status
}

setup_jichi() {
    echo "[jichi] Memastikan DHCP Relay tetap aktif untuk Network 3"

    echo 1 > /proc/sys/net/ipv4/ip_forward

    cat << 'EOF' > /etc/default/isc-dhcp-relay
SERVERS="10.93.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

    service isc-dhcp-relay restart || /etc/init.d/isc-dhcp-relay restart
    ps aux | grep dhcrelay | grep -v grep
}

case "$TARGET" in
    tengen)
        setup_tengen
        ;;
    jichi)
        setup_jichi
        ;;
    *)
        echo "Penggunaan: bash soal5.sh [tengen|jichi]"
        ;;
esac
