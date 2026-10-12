#!/bin/bash

# SCRIPT TESTING SOAL 3 - PRAKTIKUM MODUL 3 JARKOM 2026 (KELOMPOK K-59)

TARGET="${1:-jichi}"

test_jichi() {
    echo "TESTING SOAL 3 PADA NODE: jichi (DHCP Relay)"

    echo -e "\n[1] Status Layanan isc-dhcp-relay:"
    service isc-dhcp-relay status || /etc/init.d/isc-dhcp-relay status

    echo -e "\n[2] Memeriksa Proses dhcrelay:"
    if ps aux | grep -v grep | grep dhcrelay >/dev/null; then
        echo ">>> [OK] Proses dhcrelay berjalan di background:"
        ps aux | grep -v grep | grep dhcrelay
    else
        echo ">>> [ERROR] Proses dhcrelay tidak ditemukan berjalan!"
    fi

    echo -e "\n[3] Konfigurasi /etc/default/isc-dhcp-relay:"
    cat /etc/default/isc-dhcp-relay

    echo -e "\n[4] Status IPv4 Forwarding:"
    cat /proc/sys/net/ipv4/ip_forward

    echo -e "\n[5] Tes Koneksi ke DHCP Server tengen (10.93.4.10):"
    ping -c 3 10.93.4.10
}

test_tengen() {
    echo "TESTING SOAL 3 PADA NODE: tengen (DHCP Server Leases)"

    echo -e "\n[1] Status Layanan isc-dhcp-server:"
    service isc-dhcp-server status

    echo -e "\n[2] Daftar IP Lease Aktif (/var/lib/dhcp/dhcpd.leases):"
    if [ -f /var/lib/dhcp/dhcpd.leases ]; then
        grep -E "^lease" /var/lib/dhcp/dhcpd.leases || echo "Belum ada lease yang tercatat."
    fi

    echo -e "\n[3] Log Aktivitas DHCP Relay di Syslog:"
    grep -E "DHCP(DISCOVER|OFFER|REQUEST|ACK)" /var/log/syslog 2>/dev/null | tail -n 15 || echo "Log syslog kosong atau belum ada request."
}

test_client() {
    echo "TESTING SOAL 3 PADA CLIENT (Alpine Linux)"

    echo -e "\n[1] Meminta / Memperbarui IP Lease melalui DHCP (udhcpc):"
    udhcpc -i eth0 -n -q

    echo -e "\n[2] Status IP Address eth0:"
    ip -br a show eth0

    echo -e "\n[3] Routing Table:"
    ip route

    echo -e "\n[4] Pengujian Koneksi ke DHCP Server (10.93.4.10):"
    ping -c 3 10.93.4.10
}

case "$TARGET" in
    jichi)
        test_jichi
        ;;
    tengen)
        test_tengen
        ;;
    client)
        test_client
        ;;
    *)
        echo "Penggunaan: bash soal3_testing.sh [jichi|tengen|client]"
        ;;
esac
