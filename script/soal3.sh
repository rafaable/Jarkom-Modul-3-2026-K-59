#!/bin/bash

# ==============================================================================
# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 3
# ==============================================================================

TARGET="${1:-jichi}"

setup_jichi() {
    echo "[jichi] Konfigurasi DHCP Relay menuju tengen (10.93.4.10)"

    # 1. Atur DNS awal untuk unduh paket
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # 2. Pastikan IP forwarding aktif
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf 2>/dev/null
    grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf 2>/dev/null

    # 3. Instalasi paket isc-dhcp-relay tanpa prompt interaktif
    echo "=== Menginstal isc-dhcp-relay ==="
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y isc-dhcp-relay

    # 4. Konfigurasi /etc/default/isc-dhcp-relay
    # eth2: Network 2 (Divisi A)
    # eth3: Network 3 (Divisi B)
    # eth4: Network 4 (Data Center menuju tengen)
    echo "=== Menulis /etc/default/isc-dhcp-relay ==="
    cat << 'EOF' > /etc/default/isc-dhcp-relay
SERVERS="10.93.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

    # 5. Restart dan aktifkan service isc-dhcp-relay
    echo "=== Menjalankan service isc-dhcp-relay ==="
    service isc-dhcp-relay restart || /etc/init.d/isc-dhcp-relay restart

    # 6. Tampilkan status service
    echo "=== Status Layanan isc-dhcp-relay ==="
    ps aux | grep dhcrelay | grep -v grep
}

setup_tengen() {
    echo "[tengen] Menyiapkan Pool Alokasi Dinamis Network 2 & 3"

    # 1. Tulis konfigurasi dhcpd.conf dengan range pool aktif
    cat << 'EOCONF' > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

# Subnet lokal Network 4 (Data Center) - Tanpa pool dinamis
subnet 10.93.4.0 netmask 255.255.255.0 {
}

# Scope DHCP Network 2 (Divisi A) - Dengan range dinamis untuk relay
subnet 10.93.2.0 netmask 255.255.255.0 {
    range 10.93.2.10 10.93.2.50;
    option routers 10.93.2.1;
    option broadcast-address 10.93.2.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;
}

# Scope DHCP Network 3 (Divisi B) - Dengan range dinamis untuk relay
subnet 10.93.3.0 netmask 255.255.255.0 {
    range 10.93.3.10 10.93.3.50;
    option routers 10.93.3.1;
    option broadcast-address 10.93.3.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;
}
EOCONF

    # 2. Validasi sintaks
    echo "=== Validasi Konfigurasi dhcpd.conf ==="
    dhcpd -t -cf /etc/dhcp/dhcpd.conf

    # 3. Restart service isc-dhcp-server
    service isc-dhcp-server restart
    echo "=== Status Layanan isc-dhcp-server ==="
    service isc-dhcp-server status
}

case "$TARGET" in
    jichi)
        setup_jichi
        ;;
    tengen)
        setup_tengen
        ;;
    *)
        echo "Penggunaan: bash soal3.sh [jichi|tengen]"
        ;;
esac
