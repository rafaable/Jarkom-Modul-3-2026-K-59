#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 4

TARGET="${1:-tengen}"

setup_tengen() {
    echo "[tengen] Mengonfigurasi DHCP Class dan Pool Network 2"

    cat << 'EOCONF' > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

# 1. Definisi Class Klien Network 2 (Divisi A)
class "pool1-dev" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}

class "pool2-support" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}

# 2. Pemetaan Member berdasarkan MAC Address
# Tim Dev (itadori & fushiguro)
subclass "pool1-dev" 1:02:42:04:d1:3c:00;
subclass "pool1-dev" 1:02:42:8a:fc:d0:00;

# Tim Support (zenin & okkotsu)
subclass "pool2-support" 1:02:42:42:2e:33:00;
subclass "pool2-support" 1:02:42:86:56:6e:00;

# Subnet lokal Network 4 (Data Center) - Tanpa pool dinamis
subnet 10.93.4.0 netmask 255.255.255.0 {
}

# Scope DHCP Network 2 (Divisi A)
subnet 10.93.2.0 netmask 255.255.255.0 {
    option routers 10.93.2.1;
    option broadcast-address 10.93.2.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;

    # Pool 1: Tim Dev (itadori & fushiguro)
    pool {
        allow members of "pool1-dev";
        range 10.93.2.10 10.93.2.35;
    }

    # Pool 2: Tim Support (zenin & okkotsu)
    # Rentang 10.93.2.36 - 10.93.2.69 sengaja tidak dimasukkan ke pool manapun
    pool {
        allow members of "pool2-support";
        range 10.93.2.70 10.93.2.95;
    }
}

# Scope DHCP Network 3 (Divisi B) - Tetap aktif dari soal sebelumnya
subnet 10.93.3.0 netmask 255.255.255.0 {
    range 10.93.3.10 10.93.3.50;
    option routers 10.93.3.1;
    option broadcast-address 10.93.3.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;
}
EOCONF

    # Validasi sintaks dan restart layanan
    echo "Validasi sintaks dhcpd.conf:"
    dhcpd -t -cf /etc/dhcp/dhcpd.conf

    service isc-dhcp-server restart
    echo "Status layanan isc-dhcp-server:"
    service isc-dhcp-server status
}

setup_jichi() {
    echo "[jichi] Memastikan DHCP Relay tetap aktif untuk Network 2"

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
        echo "Penggunaan: bash soal4.sh [tengen|jichi]"
        ;;
esac
