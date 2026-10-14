#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# TESTING SOAL 17: Uji Pencatatan Real IP Klien pada Database

NODE_ROLE="${1:-client}"

if [ "$NODE_ROLE" == "client" ]; then
    echo "TESTING SOAL 17: KLIEN $(hostname)"
    echo "Mengirimkan request ke API endpoint (http://jujutsu.k59.com/api)..."
    
    # Pastikan nameserver mengarah ke DNS Master
    echo "nameserver 10.93.1.2" > /etc/resolv.conf
    
    RESPONSE=$(curl -s http://jujutsu.k59.com/api)
    echo "Respons dari API:"
    echo "$RESPONSE" | grep -o '{"status":.*}' || echo "$RESPONSE"

elif [ "$NODE_ROLE" == "db" ] || [ "$NODE_ROLE" == "yaga" ]; then
    echo "TESTING SOAL 17: PENGECEKAN LOG PADA DATABASE (yaga)"
    echo "Menampilkan 5 record terakhir pada tabel request_logs:"
    
    mariadb -u root << 'EOF'
USE db_shibuya_k59;
SELECT id, worker_name, client_ip, proxy_ip, created_at FROM request_logs ORDER BY id DESC LIMIT 5;
EOF

else
    echo "Penggunaan: $0 {client|db}"
fi
