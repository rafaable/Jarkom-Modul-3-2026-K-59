#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 15: Internal Load Balancer geto (Weighted Round Robin 3:1)

echo "[geto] Mengonfigurasi Internal Load Balancer Weighted Round Robin (3:1)..."

# 1. Atur IP statis geto dan nameserver untuk instalasi paket
ip addr flush dev eth0 2>/dev/null || true
ip addr add 10.93.4.2/24 dev eth0
ip link set eth0 up
ip route replace default via 10.93.4.1 dev eth0 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx dan curl
apt-get update -y
apt-get install -y nginx curl

# 3. Konfigurasi Upstream Weighted Round Robin 3:1
cat << 'EOF' > /etc/nginx/sites-available/load-balancer.conf
upstream api_cluster {
    server 10.93.4.5:80 weight=3; # nanami (menerima 3 dari setiap 4 request)
    server 10.93.4.6:80 weight=1; # todo   (menerima 1 dari setiap 4 request)
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 4. Aktifkan konfigurasi load balancer dan nonaktifkan default site
ln -sf /etc/nginx/sites-available/load-balancer.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 5. Validasi sintaks dan jalankan service
nginx -t
service nginx restart
service nginx status

echo "Konfigurasi Load Balancer geto selesai."
