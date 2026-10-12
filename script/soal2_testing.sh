#!/bin/bash

# SCRIPT TESTING SOAL 2 - PRAKTIKUM MODUL 3 JARKOM 2026 (KELOMPOK K-59)

TARGET="${1:-tengen}"

test_tengen() {
    echo "TESTING SOAL 2 PADA NODE: tengen (10.93.4.10)"

    echo -e "\n[1] Uji Sintaks Konfigurasi DHCP Server (dhcpd -t):"
    if dhcpd -t -cf /etc/dhcp/dhcpd.conf; then
        echo ">>> [HASIL: OK] Sintaks dhcpd.conf valid dan tidak ada error."
    else
        echo ">>> [HASIL: GAGAL] Ada kesalahan sintaks pada dhcpd.conf!"
    fi

    echo -e "\n[2] Status Layanan isc-dhcp-server:"
    service isc-dhcp-server status || /etc/init.d/isc-dhcp-server status

    echo -e "\n[3] Verifikasi Port UDP 67 (DHCP Service):"
    if netstat -ulnp 2>/dev/null | grep -E ':67\b'; then
        echo ">>> [HASIL: OK] Port UDP 67 aktif mendengarkan request DHCP."
    elif ss -ulpn 2>/dev/null | grep -E ':67\b'; then
        echo ">>> [HASIL: OK] Port UDP 67 aktif mendengarkan request DHCP."
    else
        echo ">>> [HASIL: PERINGATAN] Port UDP 67 belum terdeteksi aktif."
    fi

    echo -e "\n[4] Pengecekan Error 'No subnet declaration' pada Syslog:"
    if grep -i "No subnet declaration" /var/log/syslog 2>/dev/null; then
        echo ">>> [HASIL: PERINGATAN] Ditemukan log 'No subnet declaration'. Periksa subnet eth0!"
    else
        echo ">>> [HASIL: OK] Tidak ditemukan error 'No subnet declaration' pada log."
    fi

    echo -e "\n[5] Uji Konektivitas Gateway jichi (10.93.4.1):"
    ping -c 3 10.93.4.1
}

test_jichi() {
    echo "TESTING SOAL 2 PADA NODE: jichi (Router Utama)"

    echo -e "\n[1] Uji Konektivitas ke DHCP Server tengen (10.93.4.10):"
    ping -c 3 10.93.4.10

    echo -e "\n[2] Cek Interface eth4 (Gateway Network 4 Data Center):"
    ip -br a show eth4
}

case "$TARGET" in
    tengen)
        test_tengen
        ;;
    jichi)
        test_jichi
        ;;
    *)
        echo "Penggunaan: bash soal2_testing.sh [tengen|jichi]"
        ;;
esac
