# Edit Network Configuration — Switch1

### 1. jichi : Router Utama (eth1)

```
auto eth1
iface eth1 inet static
    address 10.93.1.1
    netmask 255.255.255.0
```

### 2. utahime : DNS Master

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.1.2
    netmask 255.255.255.0
    gateway 10.93.1.1
```

### 3. shoko : DNS Slave

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.1.3
    netmask 255.255.255.0
    gateway 10.93.1.1
```

### 4. gojo : Public Reverse Proxy (Nginx)

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.1.4
    netmask 255.255.255.0
    gateway 10.93.1.1
```

Ringkasan IP Switch1

| Node    | Interface | IP Address     | Gateway     |
| ------- | --------- | -------------- | ----------- |
| jichi   | eth1      | `10.93.1.1/24` | —           |
| utahime | eth0      | `10.93.1.2/24` | `10.93.1.1` |
| shoko   | eth0      | `10.93.1.3/24` | `10.93.1.1` |
| gojo    | eth0      | `10.93.1.4/24` | `10.93.1.1` |

Semua konfigurasi di atas menggunakan subnet `10.93.1.0/24`. IP server dibuat statis agar alamatnya konsisten.

# Edit Network Configuration — Switch2

Subnet Switch2 menggunakan `10.93.2.0/24`, dengan gateway `10.93.2.1` pada interface `eth2` milik `jichi`.

Karena `itadori`, `fushiguro`, `zenin`, dan `okkotsu` berperan sebagai klien DHCP, mereka akan mendapatkan IP secara otomatis. Jadi, kita tidak mengatur IP statis untuk mereka.

### 1. jichi : Router Utama (eth2)

```
auto eth2
iface eth2 inet static
    address 10.93.2.1
    netmask 255.255.255.0
```

### 2. itadori : Klien DHCP Pool 1 (Alpine)

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

### 3. fushiguro : Klien DHCP Pool 1 (Alpine)

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

### 4. zenin : Klien DHCP Pool 2 (Alpine)

```
auto lo
iface lo inet dhcp
```

### 5. okkotsu : Klien DHCP Pool 2 (Alpine)

```
auto lo
iface lo inet loopback

auto eth0 inet dhcp
```

Catatan: Konfigurasi klien Alpine di atas menggunakan format interface DHCP. Untuk `zenin` dan `okkotsu`, gunakan konfigurasi yang benar berikut ini agar konsisten.

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

## Ringkasan IP Switch2

| Node      | Interface | Metode IP             | Gateway            |
| --------- | --------- | --------------------- | ------------------ |
| jichi     | eth2      | Statis `10.93.2.1/24` | —                  |
| itadori   | eth0      | DHCP Pool 1           | Otomatis dari DHCP |
| fushiguro | eth0      | DHCP Pool 1           | Otomatis dari DHCP |
| zenin     | eth0      | DHCP Pool 2           | Otomatis dari DHCP |
| okkotsu   | eth0      | DHCP Pool 2           | Otomatis dari DHCP |

Penting: Karena klien DHCP berada di belakang `Switch3` dan `Switch9`, sedangkan DHCP server `tengen` berada di jaringan lain, kita nanti perlu mengaktifkan DHCP relay di `jichi`. Jangan khawatir kalau klien belum memperoleh IP sekarang; konfigurasi DHCP server dan relay belum selesai.

# Edit Network Configuration — Switch4

Subnet Switch4 menggunakan `10.93.3.0/24`, dengan gateway `10.93.3.1` pada interface `eth3` milik `jichi`.

### 1. jichi : Router Utama (eth3)

```
auto eth3
iface eth3 inet static
    address 10.93.3.1
    netmask 255.255.255.0
```

### 2. ino : Klien DHCP Short Lease (Alpine)

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

### 3. kusakabe : Klien DHCP Short Lease (Alpine)

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

### 4. kugisaki : Klien DHCP Fixed Address (Alpine)

```
auto lo
iface lo inet dhcp
```

### 5. miwa : Klien DHCP Long Lease (Alpine)

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

Catatan: `kugisaki` dan `miwa` perlu menggunakan format yang benar berikut ini agar interface `eth0` terkonfigurasi dengan tepat.

`kugisaki : Klien DHCP Fixed Address`

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

`miwa : Klien DHCP Long Lease`

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

## Ringkasan IP Switch4

| Node     | Interface | Metode IP             | Gateway  |
| -------- | --------- | --------------------- | -------- |
| jichi    | eth3      | Statis `10.93.3.1/24` | —        |
| ino      | eth0      | DHCP Short Lease      | Otomatis |
| kusakabe | eth0      | DHCP Short Lease      | Otomatis |
| kugisaki | eth0      | DHCP Fixed Address    | Otomatis |
| miwa     | eth0      | DHCP Long Lease       | Otomatis |

Klien di Switch4 terhubung melalui Switch5 dan Switch8. Karena semua klien tersebut memakai DHCP, durasi lease dan alamat tetap untuk `kugisaki` akan diatur dari konfigurasi DHCP server `tengen`, bukan dari file network interface klien.

# Edit Network Configuration — Switch6

Subnet Switch6 menggunakan `10.93.4.0/24`, dengan gateway `10.93.4.1` pada interface `eth4` milik `jichi`.

### 1. jichi : Router Utama (eth4)

```
auto eth4
iface eth4 inet static
    address 10.93.4.1
    netmask 255.255.255.0
```

### 2. geto : Internal Load Balancer (Nginx)

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.2
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 3. maki : Worker Frontend

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.3
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 4. panda : Worker Frontend

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.4
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 5. nanami : Worker API Utama

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.5
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 6. todo : Worker API Utama

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.6
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 7. kirara : Worker API Cadangan

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.7
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 8. tengen : DHCP Server

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.8
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 9. yoga : Belum ditentukan perannya

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.9
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 10. inumaki : Database Slave MariaDB

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.93.4.10
    netmask 255.255.255.0
    gateway 10.93.4.1
```

### 11. yaga : Database Master MariaDB

Node `yaga` belum tercantum pada pemetaan koneksi Switch10 yang kamu kirim sebelumnya. Jadi, jangan terapkan konfigurasi IP untuk `yaga` dulu sebelum koneksi fisiknya dipastikan.

## Ringkasan IP Switch6

| Node         | IP Address      | Peran                  |
| ------------ | --------------- | ---------------------- |
| jichi (eth4) | `10.93.4.1/24`  | Gateway                |
| geto         | `10.93.4.2/24`  | Internal Load Balancer |
| maki         | `10.93.4.3/24`  | Worker Frontend        |
| panda        | `10.93.4.4/24`  | Worker Frontend        |
| nanami       | `10.93.4.5/24`  | Worker API Utama       |
| todo         | `10.93.4.6/24`  | Worker API Utama       |
| kirara       | `10.93.4.7/24`  | Worker API Cadangan    |
| tengen       | `10.93.4.8/24`  | DHCP Server            |
| yoga         | `10.93.4.9/24`  | Belum ditentukan       |
| inumaki      | `10.93.4.10/24` | Database Slave         |

Penting: Alamat di atas adalah rancangan statis sementara untuk node server. Jika tugas praktikum menetapkan subnet atau IP khusus untuk DHCP server, worker, dan database, kita harus mengikuti ketentuan tersebut. `yaga` juga perlu ditambahkan ke pemetaan koneksi sebelum konfigurasi jaringannya ditetapkan.

