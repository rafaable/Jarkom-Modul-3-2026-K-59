#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 17: Public Reverse Proxy gojo (Forwarding Real IP Header)

echo "[gojo] Memastikan konfigurasi Reverse Proxy meneruskan header Real IP..."

# 1. Pastikan IP statis dan default route
ip addr flush dev eth0 2>/dev/null || true
ip addr add 10.93.1.4/24 dev eth0
ip link set eth0 up
ip route replace default via 10.93.1.1 dev eth0 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Pastikan konfigurasi vhost gojo meneruskan header X-Real-IP dan X-Forwarded-For
cat << 'EOF' > /etc/nginx/sites-available/gojo-proxy.conf
# Upstream ke Frontend Worker (Round Robin)
upstream frontend_cluster {
    server 10.93.4.3:80; # maki
    server 10.93.4.4:80; # panda
}

# Upstream ke Internal Load Balancer
upstream api_gateway {
    server 10.93.4.2:80; # geto
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name jujutsu.k59.com www.jujutsu.k59.com _;

    # Routing ke API Cluster melalui geto dengan header Real IP klien
    location /api {
        proxy_pass http://api_gateway/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Routing ke Frontend Worker
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/gojo-proxy.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 3. Validasi dan reload service Nginx
nginx -t
service nginx restart
service nginx status

echo "Konfigurasi Real IP Header pada gojo selesai."
