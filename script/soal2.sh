#!/bin/bash

# 1. Atur DNS awal dan pastikan IP statis tengen 10.93.4.10
echo "nameserver 192.168.122.1" > /etc/resolv.conf

ip addr flush dev eth0 2>/dev/null || true
ip addr add 10.93.4.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.93.4.1 dev eth0 2>/dev/null || true

# 2. Instalasi paket isc-dhcp-server
echo "=== Menginstal isc-dhcp-server ==="
apt-get update -y
apt-get install -y isc-dhcp-server

# 3. Konfigurasi interface pendengar pada /etc/default/isc-dhcp-server
echo "=== Mengonfigurasi Interface DHCP ==="
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
sed -i 's/^INTERFACES=.*/INTERFACES="eth0"/' /etc/default/isc-dhcp-server

# 4. Konfigurasi /etc/dhcp/dhcpd.conf
echo "=== Menulis /etc/dhcp/dhcpd.conf ==="
cat << 'EOCONF' > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

# Subnet lokal Network 4 (Data Center) - Dideklarasikan TANPA pool dinamis
# Wajib dideklarasikan agar daemon tidak exit dengan error: "No subnet declaration for eth0"
subnet 10.93.4.0 netmask 255.255.255.0 {
}

# Scope DHCP untuk Network 2 (Divisi A - Klien via DHCP Relay)
subnet 10.93.2.0 netmask 255.255.255.0 {
    option routers 10.93.2.1;
    option broadcast-address 10.93.2.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;
}

# Scope DHCP untuk Network 3 (Divisi B - Klien via DHCP Relay)
subnet 10.93.3.0 netmask 255.255.255.0 {
    option routers 10.93.3.1;
    option broadcast-address 10.93.3.255;
    option domain-name-servers 10.93.1.2, 10.93.1.3;
}
EOCONF

# 5. Validasi konfigurasi dhcpd
echo "=== Validasi Konfigurasi dhcpd.conf ==="
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# 6. Restart dan jalankan service isc-dhcp-server
service isc-dhcp-server restart

# 7. Cek status service
echo "=== Status Service isc-dhcp-server ==="
service isc-dhcp-server status

#!/bin/bash

echo "=========================================================="
echo "   TESTING SOAL 2: NODE tengen (DHCP Server)"
echo "=========================================================="

# 1. Validasi sintaks dhcpd.conf
echo -e "\n[1] Validasi Sintaks dhcpd.conf (dhcpd -t):"
if dhcpd -t -cf /etc/dhcp/dhcpd.conf; then
    echo ">>> [OK] Sintaks dhcpd.conf valid."
else
    echo ">>> [ERROR] Terdapat kesalahan sintaks pada dhcpd.conf."
fi

# 2. Cek status service isc-dhcp-server
echo -e "\n[2] Status Service isc-dhcp-server:"
service isc-dhcp-server status

# 3. Verifikasi Port DHCP (UDP Port 67)
echo -e "\n[3] Pengecekan Port UDP 67 (Listening):"
if netstat -ulnp 2>/dev/null | grep -E ':67\b'; then
    echo ">>> [OK] isc-dhcp-server aktif mendengarkan di UDP port 67."
elif ss -ulpn 2>/dev/null | grep -E ':67\b'; then
    echo ">>> [OK] isc-dhcp-server aktif mendengarkan di UDP port 67."
else
    echo ">>> [PERINGATAN] Port 67 belum terdeteksi aktif."
fi

# 4. Pengecekan log apakah ada error 'No subnet declaration'
echo -e "\n[4] Pengecekan Error 'No subnet declaration' di Syslog:"
if grep -i "No subnet declaration" /var/log/syslog 2>/dev/null; then
    echo ">>> [PERINGATAN] Ditemukan pesan 'No subnet declaration' di syslog."
else
    echo ">>> [OK] Bersih. Tidak ada error 'No subnet declaration'."
fi

# 5. Uji konektivitas gateway jichi
echo -e "\n[5] Tes Ping ke Gateway jichi (10.93.4.1):"
ping -c 3 10.93.4.1
echo "=========================================================="