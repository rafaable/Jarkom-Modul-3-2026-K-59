#!/bin/bash

# PERINTAH PADA NODE: jichi (Router Utama)
setup_jichi() {
    echo "=== [jichi] Mengonfigurasi Router Utama ==="
    
    # Atur DNS awal untuk unduh paket jika diperlukan
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # Aktifkan IPv4 Forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf 2>/dev/null
    grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf 2>/dev/null

    # Konfigurasi IPTables: Forwarding Policy & Source NAT (MASQUERADE) ke eth0
    iptables -P FORWARD ACCEPT
    iptables -F FORWARD
    iptables -t nat -F
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # Tampilkan verifikasi
    echo "--- IP Address jichi ---"
    ip -br a
    echo "--- Routing Table jichi ---"
    ip route
    echo "--- Status IP Forwarding ---"
    cat /proc/sys/net/ipv4/ip_forward
    echo "--- IPTables NAT Rule ---"
    iptables -t nat -L -n -v
}

# PERINTAH PADA SELURUH NODE INFRASTRUKTUR / SERVER
# Dijalankan pada:
# - Network 1 (DMZ): utahime, shoko, gojo
# - Network 4 (Data Center): tengen, geto, maki, panda, nanami, todo, kirara, yaga, inumaki
setup_server_dns() {
    echo "=== Mengatur Nameserver Awal (192.168.122.1) ==="
    # Sesuai persyaratan soal: nameserver 192.168.122.1 saat persiapan awal
    echo "nameserver 192.168.122.1" > /etc/resolv.conf
    echo "Nameserver disetel ke 192.168.122.1"
}

# 3. PERINTAH PENGUJIAN / TESTING (PEMBUKTIAN SOAL 1)
# Pengujian dari Host di Network 1 (utahime / shoko / gojo)
test_network1() {
    echo "=== [Network 1] Uji Konektivitas Gateway & Eksternal ==="
    echo "Ping Gateway jichi (10.93.1.1):"
    ping -c 3 10.93.1.1
    echo "Ping Gateway NAT (192.168.122.1):"
    ping -c 3 192.168.122.1
    echo "Ping Internet Eksternal (8.8.8.8):"
    ping -c 3 8.8.8.8
}

# Pengujian dari Host di Network 4 (tengen / geto / worker / database)
test_network4() {
    echo "=== [Network 4] Uji Konektivitas Gateway & Eksternal ==="
    echo "Ping Gateway jichi (10.93.4.1):"
    ping -c 3 10.93.4.1
    echo "Ping Gateway NAT (192.168.122.1):"
    ping -c 3 192.168.122.1
    echo "Ping Internet Eksternal (8.8.8.8):"
    ping -c 3 8.8.8.8
}

# Menu eksekusi otomatis jika script dijalankan langsung
case "$1" in
    jichi)
        setup_jichi
        ;;
    dns)
        setup_server_dns
        ;;
    test-net1)
        test_network1
        ;;
    test-net4)
        test_network4
        ;;
    *)
        echo "Panduan Penggunaan Script Soal 1:"
        echo "  bash soal1.sh jichi      -> Jalankan di jichi (aktifkan forwarding & NAT)"
        echo "  bash soal1.sh dns        -> Jalankan di node server (set nameserver awal)"
        echo "  bash soal1.sh test-net1  -> Jalankan di utahime/shoko/gojo (uji koneksi)"
        echo "  bash soal1.sh test-net4  -> Jalankan di tengen/geto/dll (uji koneksi)"
        ;;
esac
