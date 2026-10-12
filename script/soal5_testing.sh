#!/bin/bash

# SCRIPT TESTING SOAL 5 - PRAKTIKUM MODUL 3 JARKOM 2026 (KELOMPOK K-59)

TARGET="${1:-client}"

test_tengen() {
    echo "TESTING SOAL 5: NODE tengen (DHCP Server)"

    echo -e "\n[1] Status Layanan isc-dhcp-server:"
    service isc-dhcp-server status

    echo -e "\n[2] Log Lease Network 3 (/var/lib/dhcp/dhcpd.leases):"
    if [ -f /var/lib/dhcp/dhcpd.leases ]; then
        grep -E "(lease 10\.93\.3\.|starts|ends|hardware ethernet|client-hostname)" /var/lib/dhcp/dhcpd.leases || echo "Belum ada lease tercatat untuk Network 3."
    fi
}

test_jichi() {
    echo "TESTING SOAL 5: NODE jichi (DHCP Relay)"

    echo -e "\n[1] Status Layanan isc-dhcp-relay:"
    if pidof dhcrelay >/dev/null; then
        echo ">>> [OK] Service isc-dhcp-relay is running (PID: $(pidof dhcrelay))."
    else
        echo ">>> [ERROR] Service isc-dhcp-relay is not running."
    fi

    echo -e "\n[2] Memeriksa Proses dhcrelay:"
    ps aux | grep -v grep | grep dhcrelay

    echo -e "\n[3] Tes Konektivitas ke DHCP Server tengen (10.93.4.10):"
    ping -c 3 10.93.4.10
}

test_client() {
    CLIENT_NAME="$(hostname)"
    echo "TESTING SOAL 5: KLIEN $CLIENT_NAME (Alpine Linux)"

    echo -e "\n[1] Meminta Lease IP melalui DHCP (udhcpc):"
    udhcpc -i eth0 -n -q

    echo -e "\n[2] Status IP Address eth0:"
    ip -br a show eth0

    echo -e "\n[3] Routing Table:"
    ip route

    echo -e "\n[4] Konfigurasi DNS & Domain Search (/etc/resolv.conf):"
    cat /etc/resolv.conf

    echo -e "\n[5] Pengujian Koneksi ke Gateway (10.93.3.1):"
    ping -c 3 10.93.3.1
}

case "$TARGET" in
    tengen)
        test_tengen
        ;;
    jichi)
        test_jichi
        ;;
    client)
        test_client
        ;;
    *)
        echo "Penggunaan: bash soal5_testing.sh [tengen|jichi|client]"
        ;;
esac
