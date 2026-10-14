#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 17: Internal Load Balancer geto (Trusted Proxy & Real IP Verification)

echo "[geto] Mengonfigurasi Trusted Proxy dan Verifikasi Real IP..."

# 1. Pastikan IP statis dan default route
ip addr flush dev eth0 2>/dev/null || true
ip addr add 10.93.4.2/24 dev eth0
ip link set eth0 up
ip route replace default via 10.93.4.1 dev eth0 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Konfigurasi Nginx: Hanya percayai proxy gojo (10.93.1.4)
cat << 'EOF' > /etc/nginx/sites-available/load-balancer.conf
upstream api_cluster {
    server 10.93.4.5:80 weight=3; # nanami (75%)
    server 10.93.4.6:80 weight=1; # todo   (25%)
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Keamanan Real IP: Hanya percayai header dari Public Reverse Proxy gojo (10.93.1.4)
    set_real_ip_from 10.93.1.4;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        # $remote_addr sekarang merupakan IP klien asli yang telah divalidasi oleh realip module
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/load-balancer.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 3. Validasi sintaks dan restart layanan
nginx -t
service nginx restart
service nginx status

echo "Konfigurasi Trusted Proxy pada geto selesai."
