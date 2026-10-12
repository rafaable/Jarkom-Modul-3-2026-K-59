# Laporan Resmi Praktikum Komdat-Jarkom Modul 1

> **Kelompok K-59**
> * Salsabila Rafa Syafira (5027251059)
> * Fiorellin Ilona (5027251082)

---

## Daftar Isi
* [Soal 1](#soal-1)
* [Soal 2](#soal-2)
* [Soal 3](#soal-3)
* [Soal 4](#soal-4)
* [Soal 5](#soal-5)
* [Soal 6](#soal-6)
* [Soal 7](#soal-7)
* [Soal 8](#soal-8)
* [Soal 9](#soal-9)
* [Soal 10](#soal-10)
* [Soal 11](#soal-11)
* [Soal 12](#soal-12)
* [Soal 13](#soal-13)
* [Soal 14](#soal-14)
* [Soal 15](#soal-15)
* [Soal 16](#soal-16)
* [Soal 17](#soal-17)
* [Soal 18](#soal-18)
* [Soal 19](#soal-19)
* [Soal 20](#soal-20)

---

### Informasi Jaringan

- IP Address Host: `10.4.89.250`
- Prefix IP: `10.93.x.x`
- Platform: GNS3 Web

### Pembagian Peran Node GNS3

| Node | Peran | OS |
|---|---|---|
| `jichi` | Router utama, DHCP relay | Debian |
| `tengen` | DHCP server | Debian |
| `utahime` | DNS master | Debian |
| `shoko` | DNS slave | Debian |
| `gojo` | Public reverse proxy Nginx | Debian |
| `itadori` | Klien DHCP Pool 1 | Alpine |
| `fushiguro` | Klien DHCP Pool 1 | Alpine |
| `zenin` | Klien DHCP Pool 2 | Alpine |
| `okkotsu` | Klien DHCP Pool 2 | Alpine |
| `ino` | Klien dengan short lease | Alpine |
| `kusakabe` | Klien dengan short lease | Alpine |
| `miwa` | Klien dengan long lease | Alpine |
| `kugisaki` | Klien dengan fixed address | Alpine |
| `geto` | Internal load balancer Nginx | Debian |
| `maki` | Worker frontend | Debian |
| `panda` | Worker frontend | Debian |
| `nanami` | Worker API utama | Debian |
| `todo` | Worker API utama | Debian |
| `kirara` | Worker API cadangan | Debian |
| `yaga` | Database master MariaDB | Debian |
| `inumaki` | Database slave MariaDB | Debian |

### Pemetaan Node dan Koneksi

| No. | Node Asal | Interface Asal | Node Tujuan | Interface Tujuan |
|---:|---|---|---|---|
| 1 | NAT1 (nat0) | - | jichi | eth0 |
| 2 | jichi | eth1 | Switch1 | e0 |
| 3 | jichi | eth2 | Switch2 | e0 |
| 4 | jichi | eth3 | Switch4 | e0 |
| 5 | jichi | eth4 | Switch6 | e0 |
| 6 | Switch1 | e1 | utahime | eth0 |
| 7 | Switch1 | e2 | shoko | eth0 |
| 8 | Switch1 | e3 | gojo | eth0 |
| 9 | Switch2 | e1 | Switch3 | e0 |
| 10 | Switch2 | e2 | Switch9 | e0 |
| 11 | Switch3 | e1 | itadori | eth0 |
| 12 | Switch3 | e2 | fushiguro | eth0 |
| 13 | Switch9 | e1 | zenin | eth0 |
| 14 | Switch9 | e2 | okkotsu | eth0 |
| 15 | Switch6 | e1 | Switch7 | e0 |
| 16 | Switch6 | e2 | Switch10 | e0 |
| 17 | Switch7 | e1 | geto | e0 |
| 18 | Switch7 | e2 | maki | e0 |
| 19 | Switch7 | e3 | panda | e0 |
| 20 | Switch7 | e4 | nanami | e0 |
| 21 | Switch7 | e5 | todo | e0 |
| 22 | Switch7 | e6 | kirara | e0 |
| 23 | Switch10 | e1 | tengen | e0 |
| 24 | Switch10 | e2 | yoga | e0 |
| 25 | Switch10 | e3 | inumaki | e0 |
| 26 | Switch4 | e1 | Switch5 | e0 |
| 27 | Switch4 | e2 | Switch8 | e0 |
| 28 | Switch5 | e1 | ino | eth0 |
| 29 | Switch5 | e2 | kusakabe | eth0 |
| 30 | Switch8 | e1 | kugisaki | eth0 |
| 31 | Switch8 | e2 | miwa | eth0 |

# Pembahasan

## Soal 1
### Perintah soal
Konfigurasi jichi: eth0 WAN dari NAT, eth1-eth4 gateway Network 1-4  
Aktifkan IPv4 forwarding dan source NAT (MASQUERADE)  
Tetapkan IP statis host infrastruktur dan nameserver 192.168.122.1   
Uji konektivitas setiap host ke gateway dan akses eksternal   

### Langkah pengerjaan
1. Config di root jichi
   
   ```bash
   cat << 'EOF' > /root/soal1.sh
   #!/bin/bash

   # Atur nameserver awal
   echo "nameserver 192.168.122.1" > /etc/resolv.conf

   # Aktifkan IPv4 Forwarding
   echo 1 > /proc/sys/net/ipv4/ip_forward
   grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
   sysctl -p /etc/sysctl.conf 2>/dev/null

   # Konfigurasi IPTables NAT & Forwarding
   iptables -P FORWARD ACCEPT
   iptables -F FORWARD
   iptables -t nat -F
   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

   echo "Konfigurasi jichi (Soal 1) selesai dan aktif."
   EOF
   ```
   Jalankan script
   ```
   chmod +x /root/soal1.sh  
   /root/soal1.sh  
   ```
   Untuk semua node yang lain, jalankan ini
   ```
   echo "nameserver 192.168.122.1" > /etc/resolv.conf
   ```

2. Pengujian  
   Dari jichi
   ```
   ping -c 3 8.8.8.8
   ```
   Dari tengen  
   ```
   ping -c 3 10.93.4.1
   ping -c 3 192.168.122.1
   ping -c 3 8.8.8.8
   ```
   Dari utahime / gojo
   ```
   ping -c 3 10.93.1.1
   ```
<br>![alt text](assets/image.png)<br>
---

## Soal 2
### Perintah soal
Tengen, penjaga pusat distribusi di Data Center, harus mengambil alih pengalokasian alamat bagi wilayah yang membutuhkan konfigurasi dinamis:
1. **Konfigurasi `isc-dhcp-server` pada `tengen` (`10.93.4.10`)**: Menginstal dan mengonfigurasi DHCP server pada node `tengen`.
2. **Deklarasikan Network 4 (`10.93.4.0/24`) sebagai subnet lokal tanpa pool dinamis**:
   - ISC DHCP Server mewajibkan deklarasi subnet tempat interface fisik yang mendengarkan berada (`eth0` dengan IP `10.93.4.10`).
   - Jika subnet `10.93.4.0/24` tidak dideklarasikan di `dhcpd.conf`, service akan gagal start / crash dengan pesan error: `"No subnet declaration for eth0 (10.93.4.10)"`.
   - Karena Network 4 adalah Data Center dengan IP statis, deklarasi dibuat kosong `{}` tanpa parameter `range`.
3. **Siapkan scope DHCP untuk Network 2 (`10.93.2.0/24`) dan Network 3 (`10.93.3.0/24`)**:
   - Scope untuk Divisi A (Network 2) dan Divisi B (Network 3) didefinisikan agar saat request DHCP diteruskan oleh DHCP Relay (`jichi`), `tengen` dapat mengenali subnet asal request dan mendistribusikan parameter jaringan (seperti gateway router, broadcast, dan DNS server).
4. **Validasi konfigurasi dan pastikan service aktif tanpa error**:
   - Mengecek sintaks konfigurasi menggunakan perintah `dhcpd -t -cf /etc/dhcp/dhcpd.conf`.
   - Memastikan service berjalan (`active (running)`) dan listening pada UDP port 67.
![alt text](image.png)
---

### Penempatan Script pada Node

Seluruh script instalasi, konfigurasi, dan pengujian disimpan di direktori `/root` masing-masing node agar tidak hilang.

| Node | File Script | Fungsi |
|---|---|---|
| **`tengen`** | `/root/soal2.sh` | Instalasi `isc-dhcp-server`, konfigurasi interface `eth0`, deklarasi subnet Network 4, 2, 3 di `dhcpd.conf`, validasi, dan restart service |
| **`tengen`** | `/root/soal2_testing.sh` | Validasi sintaks `dhcpd -t`, cek status layanan, verifikasi port UDP 67, dan cek syslog |
| **`jichi`** | `/root/soal2_testing.sh` | Pengujian konektivitas router jichi ke DHCP Server `tengen` (Network 4) |

---

### Langkah Pengerjaan

#### 1. Pada Node `tengen` (DHCP Server)

Buka terminal node **`tengen`**, buat file `/root/soal2.sh`:

```bash
nano /root/soal2.sh
```

Isikan script berikut:

```bash
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
```

Beri izin eksekusi dan jalankan script:

```bash
chmod +x /root/soal2.sh
/root/soal2.sh
```

---

### Script Testing

#### 1. Pada Node `tengen`

Buka terminal node **`tengen`**, buat file `/root/soal2_testing.sh`:

```bash
nano /root/soal2_testing.sh
```

Isikan script pengujian berikut:

```bash
#!/bin/bash

echo "TESTING SOAL 2: NODE tengen (DHCP Server)"

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
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal2_testing.sh
/root/soal2_testing.sh
```

---

#### 2. Pada Node `jichi`

Buka terminal node **`jichi`**, buat file `/root/soal2_testing.sh`:

```bash
nano /root/soal2_testing.sh
```

Isikan script pengujian berikut:

```bash
#!/bin/bash

echo "TESTING SOAL 2: NODE jichi (Koneksi ke DHCP Server)"

echo -e "\n[1] Uji Ping ke DHCP Server tengen (10.93.4.10):"
ping -c 3 10.93.4.10

echo -e "\n[2] Status Interface eth4 (Gateway Network 4):"
ip -br a show eth4
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal2_testing.sh
/root/soal2_testing.sh
```
![alt text](assets/soal2_1.png)  

<br>Tampilan di node jichi<br>  

![alt text](assets/soal2_2.png)
---

## Soal 3
### Perintah soal
Permintaan alamat dari Divisi A dan Divisi B tidak dapat menyeberangi subnet secara langsung:
1. **Masalah Subnet & DHCP Broadcast:**
   - Klien Divisi A berada di **Network 2 (`10.93.2.0/24`)** dan Klien Divisi B berada di **Network 3 (`10.93.3.0/24`)**, sedangkan DHCP Server `tengen` berada di **Network 4 (`10.93.4.10`)**.
   - Paket `DHCPDISCOVER` dikirimkan secara broadcast (`255.255.255.255`) oleh klien. Secara default, router tidak akan meneruskan paket broadcast antar subnet.
2. **Konfigurasi DHCP Relay pada `jichi`:**
   - Router `jichi` dikonfigurasikan sebagai DHCP Relay menggunakan daemon `isc-dhcp-relay`.
   - Relay bertugas menangkap paket broadcast DHCP dari interface klien (**`eth2`** untuk Network 2 dan **`eth3`** untuk Network 3), menyematkan IP interface gateway router pada field `giaddr` (*Gateway IP Address*), lalu mem-forward paket tersebut secara unicast ke DHCP Server `tengen` (`10.93.4.10`) melalui **`eth4`**.
3. **Penyediaan Pool Range pada `tengen`:**
   - Agar `tengen` dapat memberikan lease saat request tiba melalui relay, scope Network 2 dan Network 3 harus memiliki rentang pool IP yang aktif.
4. **Pembuktian Lease pada Klien:**
   - Menguji permintaan IP pada klien Network 2 (`itadori`) dan Network 3 (`ino`) untuk membuktikan bahwa klien berhasil memperoleh konfigurasi IP, subnet mask, gateway, dan DNS melalui DHCP Relay.

---

### Penempatan Script pada Node

Seluruh script instalasi, konfigurasi, dan pengujian disimpan di direktori `/root` masing-masing node agar tidak hilang.

| Node | File Script | Fungsi |
|---|---|---|
| **`tengen`** | `/root/soal3.sh` | Menambahkan rentang IP dinamis (*pool*) untuk Network 2 & 3 pada `dhcpd.conf` dan restart service |
| **`jichi`** | `/root/soal3.sh` | Instalasi `isc-dhcp-relay`, pengaturan interface `eth2 eth3 eth4`, target server `10.93.4.10`, dan start service relay |
| **`jichi`** | `/root/soal3_testing.sh` | Memverifikasi status layanan `isc-dhcp-relay`, proses `dhcrelay`, dan forwarding |
| **`tengen`** | `/root/soal3_testing.sh` | Memeriksa riwayat lease di `/var/lib/dhcp/dhcpd.leases` dan log syslog |
| **`itadori` / `ino`** | `/root/soal3_testing.sh` | Meminta IP via DHCP (`udhcpc`), menampilkan alamat IP, route, dan uji konektivitas |

---

### Langkah Pengerjaan

#### 1. Pada Node `tengen` (DHCP Server)

Buka terminal node **`tengen`**, buat file `/root/soal3.sh`:

```bash
nano /root/soal3.sh
```

Isikan script berikut:

```bash
#!/bin/bash
# Script config tengen (Penyediaan Pool untuk Relay)

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

# Validasi dan restart service
echo "=== Validasi Konfigurasi dhcpd.conf ==="
dhcpd -t -cf /etc/dhcp/dhcpd.conf

service isc-dhcp-server restart
echo "=== Status Layanan isc-dhcp-server ==="
service isc-dhcp-server status
```

Beri izin eksekusi dan jalankan script di `tengen`:

```bash
chmod +x /root/soal3.sh
/root/soal3.sh
```

---

#### 2. Pada Node `jichi` (DHCP Relay)

Buka terminal node **`jichi`**, buat file `/root/soal3.sh`:

```bash
nano /root/soal3.sh
```

Isikan script berikut:

```bash
#!/bin/bash
# config jichi (DHCP Relay)

# 1. Atur DNS awal untuk unduh paket jika diperlukan
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Pastikan IP forwarding aktif
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf 2>/dev/null
grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf 2>/dev/null

# 3. Instal paket isc-dhcp-relay secara non-interaktif
echo "=== Menginstal isc-dhcp-relay ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y isc-dhcp-relay

# 4. Konfigurasi /etc/default/isc-dhcp-relay
# eth2: Network 2 (Divisi A)
# eth3: Network 3 (Divisi B)
# eth4: Network 4 (menghubungkan jichi ke DHCP Server tengen 10.93.4.10)
echo "=== Menulis /etc/default/isc-dhcp-relay ==="
cat << 'EOF' > /etc/default/isc-dhcp-relay
SERVERS="10.93.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

# 5. Restart dan jalankan service isc-dhcp-relay
echo "=== Menjalankan service isc-dhcp-relay ==="
service isc-dhcp-relay restart || /etc/init.d/isc-dhcp-relay restart

# 6. Tampilkan status service
echo "=== Status Layanan isc-dhcp-relay ==="
ps aux | grep dhcrelay | grep -v grep
```

Beri izin eksekusi dan jalankan script di `jichi`:

```bash
chmod +x /root/soal3.sh
/root/soal3.sh
```

---

### Script Testing

#### 1. Pada Node `jichi` (Pengujian Status Relay)

Buka terminal node **`jichi`**, buat file `/root/soal3_testing.sh`:

```bash
nano /root/soal3_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
echo "   TESTING SOAL 3: NODE jichi (DHCP Relay)"

echo -e "\n[1] Status Layanan isc-dhcp-relay:"
service isc-dhcp-relay status || /etc/init.d/isc-dhcp-relay status

echo -e "\n[2] Memeriksa Proses dhcrelay:"
if ps aux | grep -v grep | grep dhcrelay >/dev/null; then
    echo ">>> [OK] Daemon dhcrelay aktif berjalan:"
    ps aux | grep -v grep | grep dhcrelay
else
    echo ">>> [ERROR] Daemon dhcrelay tidak ditemukan berjalan!"
fi

echo -e "\n[3] Konfigurasi /etc/default/isc-dhcp-relay:"
cat /etc/default/isc-dhcp-relay

echo -e "\n[4] Status IPv4 Forwarding:"
cat /proc/sys/net/ipv4/ip_forward

echo -e "\n[5] Tes Konektivitas ke DHCP Server tengen (10.93.4.10):"
ping -c 3 10.93.4.10
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal3_testing.sh
/root/soal3_testing.sh
```

---

#### 2. Pada Node `tengen` (Pengujian Leases di Server)

Buka terminal node **`tengen`**, buat file `/root/soal3_testing.sh`:

```bash
nano /root/soal3_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
echo "   TESTING NODE tengen (DHCP Server Leases)"

echo -e "\n[1] Status Layanan isc-dhcp-server:"
service isc-dhcp-server status

echo -e "\n[2] Daftar IP Lease Aktif (/var/lib/dhcp/dhcpd.leases):"
if [ -f /var/lib/dhcp/dhcpd.leases ]; then
    grep -E "^lease" /var/lib/dhcp/dhcpd.leases || echo "Belum ada lease yang tercatat."
fi

echo -e "\n[3] Log Aktivitas Relay DHCP di Syslog:"
grep -E "DHCP(DISCOVER|OFFER|REQUEST|ACK)" /var/log/syslog 2>/dev/null | tail -n 15 || echo "Log syslog kosong atau belum ada request."
echo "=========================================================="
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal3_testing.sh
/root/soal3_testing.sh
```

---

#### 3. Pada Klien Network 2 (`itadori`) dan Network 3 (`ino`)

Jalankan pengujian ini pada terminal klien **`itadori`** (Divisi A) dan **`ino`** (Divisi B) untuk meminta alamat melalui relay:

Buat file `/root/soal3_testing.sh` pada klien:

```bash
nano /root/soal3_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
echo "   TESTING KLIEN DHCP (Alpine Linux)"

echo -e "\n[1] Meminta / Memperbarui IP Lease melalui DHCP (udhcpc):"
udhcpc -i eth0 -n -q

echo -e "\n[2] Status IP Address eth0:"
ip -br a show eth0

echo -e "\n[3] Routing Table:"
ip route

echo -e "\n[4] Pengujian Koneksi ke DHCP Server (10.93.4.10):"
ping -c 3 10.93.4.10
```

Beri izin eksekusi dan jalankan pada masing-masing klien:

```bash
chmod +x /root/soal3_testing.sh
/root/soal3_testing.sh
```

![alt text](assets/soal3_1.png)
---

## Soal 4
### Perintah soal
Permintaan pembagian dua pool DHCP pada Network 2 untuk tim Dev dan Support di Divisi A:
1. **Pembagian Kelompok & Alokasi Pool:**
   - **Tim Dev:** Personal `itadori` dan `fushiguro` harus memperoleh alamat dari **Pool 1 (`10.93.2.10 - 10.93.2.35`)**.
   - **Tim Support:** Personal `zenin` dan `okkotsu` harus memperoleh alamat dari **Pool 2 (`10.93.2.70 - 10.93.2.95`)**.
   - **Rentang Terlarang:** Alamat `10.93.2.36 - 10.93.2.69` tidak boleh dialokasikan ke siapapun.
2. **Penerapan DHCP Class & Subclass (Berdasarkan MAC Address):**
   - Karena keempat klien berada di subnet yang sama (`10.93.2.0/24`), ISC DHCP Server menggunakan fitur **`class`** dan **`subclass`** untuk memetakan MAC Address masing-masing klien:
     - `itadori`: `02:42:04:d1:3c:00` (Tim Dev -> Pool 1)
     - `fushiguro`: `02:42:8a:fc:d0:00` (Tim Dev -> Pool 1)
     - `zenin`: `02:42:42:2e:33:00` (Tim Support -> Pool 2)
     - `okkotsu`: `02:42:86:56:6e:00` (Tim Support -> Pool 2)
   - Di dalam blok `subnet 10.93.2.0`, didefinisikan dua blok `pool` terpisah:
     - `pool { allow members of "pool1-dev"; range 10.93.2.10 10.93.2.35; }`
     - `pool { allow members of "pool2-support"; range 10.93.2.70 10.93.2.95; }`
   - Rentang `10.93.2.36 - 10.93.2.69` otomatis terlindungi dan tidak akan pernah diberikan ke klien karena tidak dicantumkan pada blok pool manapun.

---

### Penempatan Script pada Node

| Node | File Script | Fungsi |
|---|---|---|
| **`tengen`** | `/root/soal4.sh` | Mengonfigurasi DHCP class, pemetaan subclass MAC Address, dan 2 pool terpisah di `dhcpd.conf` |
| **`jichi`** | `/root/soal4.sh` | Memastikan DHCP Relay tetap aktif dan meneruskan paket Network 2 ke `tengen` |
| **`tengen`** | `/root/soal4_testing.sh` | Memeriksa log alokasi lease di `/var/lib/dhcp/dhcpd.leases` |
| **`jichi`** | `/root/soal4_testing.sh` | Memeriksa proses relay dan konektivitas |
| **`itadori` / `fushiguro`** | `/root/soal4_testing.sh` | Meminta IP DHCP dan memverifikasi alokasi Pool 1 (`10.93.2.10 - 10.93.2.35`) |
| **`zenin` / `okkotsu`** | `/root/soal4_testing.sh` | Meminta IP DHCP dan memverifikasi alokasi Pool 2 (`10.93.2.70 - 10.93.2.95`) |

---

### Langkah Pengerjaan

#### 1. Pada Node `tengen` (DHCP Server)

Buka terminal node **`tengen`**, buat file `/root/soal4.sh`:

```bash
nano /root/soal4.sh
```

Isikan script berikut:

```bash
#!/bin/bash
# Script config tengen (DHCP Class & Pool Network 2)

cat << 'EOCONF' > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

# 1. Definisi Class untuk Klien Network 2 (Divisi A)
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

    # Pool 1: Khusus Tim Dev (10.93.2.10 - 10.93.2.35)
    pool {
        allow members of "pool1-dev";
        range 10.93.2.10 10.93.2.35;
    }

    # Pool 2: Khusus Tim Support (10.93.2.70 - 10.93.2.95)
    # Rentang 10.93.2.36 - 10.93.2.69 sengaja dikosongkan dan tidak dialokasikan
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

# Validasi dan restart service
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
service isc-dhcp-server status
```

Beri izin eksekusi dan jalankan di `tengen`:

```bash
chmod +x /root/soal4.sh
/root/soal4.sh
```

---

#### 2. Pada Node `jichi` (DHCP Relay)

Buka terminal node **`jichi`**, buat file `/root/soal4.sh`:

```bash
nano /root/soal4.sh
```

Isikan script berikut:

```bash
#!/bin/bash
# Script config jichi (Memastikan Relay Aktif)

echo 1 > /proc/sys/net/ipv4/ip_forward

cat << 'EOF' > /etc/default/isc-dhcp-relay
SERVERS="10.93.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

service isc-dhcp-relay restart || /etc/init.d/isc-dhcp-relay restart
ps aux | grep dhcrelay | grep -v grep
```

Beri izin eksekusi dan jalankan di `jichi`:

```bash
chmod +x /root/soal4.sh
/root/soal4.sh
```

---

### Script Testing

#### 1. Pada Node `tengen` (Pengujian Lease Server)

Buka terminal node **`tengen`**, buat file `/root/soal4_testing.sh`:

```bash
nano /root/soal4_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
echo "TESTING SOAL 4: NODE tengen (DHCP Server)"

echo -e "\n[1] Status Layanan isc-dhcp-server:"
service isc-dhcp-server status

echo -e "\n[2] Log Lease Network 2 (/var/lib/dhcp/dhcpd.leases):"
if [ -f /var/lib/dhcp/dhcpd.leases ]; then
    grep -E "(lease 10\.93\.2\.|client-hostname|uid)" /var/lib/dhcp/dhcpd.leases || echo "Belum ada lease tercatat untuk Network 2."
fi
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal4_testing.sh
/root/soal4_testing.sh
```
<br>![alt text](assets/soal4_1.png)<br>
---

#### 2. Pada Node `jichi` (Pengujian Status Relay)

Buka terminal node **`jichi`**, buat file `/root/soal4_testing.sh`:

```bash
nano /root/soal4_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
echo "TESTING SOAL 4: NODE jichi (DHCP Relay)"

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
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal4_testing.sh
/root/soal4_testing.sh
```
<br>![alt text](assets/soal4_2.png)<br>
---

#### 3. Pada Klien Divisi A (`itadori`, `fushiguro`, `zenin`, `okkotsu`)

Jalankan pengujian ini pada masing-masing terminal klien Divisi A:

Buat file `/root/soal4_testing.sh` pada klien:

```bash
nano /root/soal4_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
CLIENT_NAME="$(hostname)"
echo "TESTING SOAL 4: KLIEN $CLIENT_NAME (Alpine Linux)"

echo -e "\n[1] Meminta Lease IP melalui DHCP (udhcpc):"
udhcpc -i eth0 -n -q

echo -e "\n[2] Status IP Address eth0:"
ip -br a show eth0

echo -e "\n[3] Routing Table:"
ip route

echo -e "\n[4] Pengujian Koneksi ke Gateway (10.93.2.1):"
ping -c 3 10.93.2.1
```

Beri izin eksekusi dan jalankan pada masing-masing klien:

```bash
chmod +x /root/soal4_testing.sh
/root/soal4_testing.sh
```

> **Target Alokasi IP yang Diharapkan:**
> - `itadori`: Mendapat IP antara `10.93.2.10` s.d. `10.93.2.35` (Pool 1 Dev)
> - `fushiguro`: Mendapat IP antara `10.93.2.10` s.d. `10.93.2.35` (Pool 1 Dev)
> - `zenin`: Mendapat IP antara `10.93.2.70` s.d. `10.93.2.95` (Pool 2 Support)
> - `okkotsu`: Mendapat IP antara `10.93.2.70` s.d. `10.93.2.95` (Pool 2 Support)  
<br>

![alt text](assets/soal4_3.png)<br>
![alt text](assets/soal4_4.png)<br>
![alt text](assets/soal4_5.png)<br>
![alt text](assets/soal4_6.png)
---

## Soal 5
### Perintah soal

Permintaan konfigurasi lease time berbeda dan opsi jaringan pada Network 3 (Divisi B):
1. **Klasifikasi Lease Time & Pool Alokasi:**
   - **Tim Short Lease (`ino` dan `kusakabe`):**
     - Durasi operasional: 30 menit (1800 detik).
     - Rentang Pool: **`10.93.3.10 - 10.93.3.89`**.
     - Nilai parameter: `default-lease-time 1800; max-lease-time 1800;`.
   - **Tim Long Lease (`miwa`):**
     - Durasi operasional: 12 jam (43200 detik).
     - Rentang Pool: **`10.93.3.100 - 10.93.3.199`**.
     - Nilai parameter: `default-lease-time 43200; max-lease-time 43200;`.
2. **Distribusi DHCP Options pada Network 3:**
   - Router Gateway: `10.93.3.1` (`option routers 10.93.3.1;`).
   - Broadcast Address: `10.93.3.255` (`option broadcast-address 10.93.3.255;`).
   - DNS Server: `10.93.1.2` dan `10.93.1.3` (`option domain-name-servers 10.93.1.2, 10.93.1.3;`).
   - Domain Search: `k59.com` (`option domain-name "k59.com"; option domain-search "k59.com";`).
3. **Penerapan DHCP Class & Subclass (Berdasarkan MAC Address):**
   - Dibuat dua class pada DHCP server: `"short-lease"` dan `"long-lease"` dengan pencocokan MAC Address:
     - `ino`: `02:42:d2:0f:95:00` (Short Lease 1800s / 30 menit)
     - `kusakabe`: `02:42:e7:2e:22:00` (Short Lease 1800s / 30 menit)
     - `miwa`: `f2:dd:ec:51:c9:cb` (Long Lease 43200s / 12 jam)
   - Parameter lease time dikonfigurasi spesifik per pool sehingga setiap kelas menerima masa sewa IP sesuai kebijakan.

---

### Penempatan Script pada Node

| Node | File Script | Fungsi |
|---|---|---|
| **`tengen`** | `/root/soal5.sh` | Konfigurasi class short lease & long lease, option DNS, search domain, serta pool Network 3 di `dhcpd.conf` |
| **`jichi`** | `/root/soal5.sh` | Memastikan DHCP Relay tetap aktif melayani Network 3 (`eth3`) ke `tengen` |
| **`tengen`** | `/root/soal5_testing.sh` | Memeriksa log durasi sewa lease pada `/var/lib/dhcp/dhcpd.leases` |
| **`jichi`** | `/root/soal5_testing.sh` | Memeriksa proses relay dan konektivitas |
| **`ino` / `kusakabe`** | `/root/soal5_testing.sh` | Meminta IP DHCP, verifikasi rentang pool short lease (`10.93.3.10 - 10.93.3.89`), dan cek `/etc/resolv.conf` |
| **`miwa`** | `/root/soal5_testing.sh` | Meminta IP DHCP, verifikasi rentang pool long lease (`10.93.3.100 - 10.93.3.199`), dan cek `/etc/resolv.conf` |

---

### Langkah Pengerjaan

#### 1. Pada Node `tengen` (DHCP Server)

Buka terminal node **`tengen`**, buat file `/root/soal5.sh`:

```bash
nano /root/soal5.sh
```

Isikan script berikut:

```bash
#!/bin/bash
# Script config tengen (Soal 5: Lease Time, DNS & Domain Search Network 3)

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

# Subclass Klien Network 3 (Berdasarkan MAC Address)
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
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
service isc-dhcp-server status
```

Beri izin eksekusi dan jalankan di `tengen`:

```bash
chmod +x /root/soal5.sh
/root/soal5.sh
```

---

#### 2. Pada Node `jichi` (DHCP Relay)

Buka terminal node **`jichi`**, buat file `/root/soal5.sh`:

```bash
nano /root/soal5.sh
```

Isikan script berikut:

```bash
#!/bin/bash
# Script config jichi (Memastikan Relay Aktif untuk Network 3)

echo 1 > /proc/sys/net/ipv4/ip_forward

cat << 'EOF' > /etc/default/isc-dhcp-relay
SERVERS="10.93.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

service isc-dhcp-relay restart || /etc/init.d/isc-dhcp-relay restart
ps aux | grep dhcrelay | grep -v grep
```

Beri izin eksekusi dan jalankan di `jichi`:

```bash
chmod +x /root/soal5.sh
/root/soal5.sh
```

---

### Script Testing

#### 1. Pada Node `tengen` (Pengujian Lease Server)

Buka terminal node **`tengen`**, buat file `/root/soal5_testing.sh`:

```bash
nano /root/soal5_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
echo "TESTING SOAL 5: NODE tengen (DHCP Server)"

echo -e "\n[1] Status Layanan isc-dhcp-server:"
service isc-dhcp-server status

echo -e "\n[2] Log Lease Network 3 (/var/lib/dhcp/dhcpd.leases):"
if [ -f /var/lib/dhcp/dhcpd.leases ]; then
    grep -E "(lease 10\.93\.3\.|starts|ends|hardware ethernet|client-hostname)" /var/lib/dhcp/dhcpd.leases || echo "Belum ada lease tercatat untuk Network 3."
fi
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal5_testing.sh
/root/soal5_testing.sh
```
---

#### 2. Pada Node `jichi` (Pengujian Status Relay)

Buka terminal node **`jichi`**, buat file `/root/soal5_testing.sh`:

```bash
nano /root/soal5_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
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
```

Beri izin eksekusi dan jalankan:

```bash
chmod +x /root/soal5_testing.sh
/root/soal5_testing.sh
```

---

#### 3. Pada Klien Divisi B (`ino`, `kusakabe`, `miwa`)

Buka terminal klien **`ino`**, **`kusakabe`**, atau **`miwa`**:

Buat file `/root/soal5_testing.sh` pada klien:

```bash
nano /root/soal5_testing.sh
```

Isikan script berikut:

```bash
#!/bin/bash
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
```

Beri izin eksekusi dan jalankan pada masing-masing klien:

```bash
chmod +x /root/soal5_testing.sh
/root/soal5_testing.sh
```

> **Target Alokasi IP dan Lease yang Diharapkan:**
> - `ino`: Mendapat IP antara `10.93.3.10` s.d. `10.93.3.89` (Short Lease 1800 detik / 30 menit)
> - `kusakabe`: Mendapat IP antara `10.93.3.10` s.d. `10.93.3.89` (Short Lease 1800 detik / 30 menit)
> - `miwa`: Mendapat IP antara `10.93.3.100` s.d. `10.93.3.199` (Long Lease 43200 detik / 12 jam)
> - Seluruh klien menerima DNS `10.93.1.2`, `10.93.1.3` dan search domain `k59.com` di `/etc/resolv.conf`.

![alt text](assets/soal5_3.png)<br>  
![alt text](assets/soal5_4.png)<br>
![alt text](assets/soal5_5.png)
---

## Soal 6
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```

---

## Soal 7
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
---

## Soal 8
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 9
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 10
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 11
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 12
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 13
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 14
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 15
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 16
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 17
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 18
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 19
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
 ---

## Soal 20
### Perintah soal

### Langkah pengerjaan
1. Buat blablabla
   
   ```bash
   ini script
   ```
2. Buat blablabla
   
   ```bash
   ini script
   ```
3. Buat blablabla
   
   ```bash
   ini script
   ```
 
