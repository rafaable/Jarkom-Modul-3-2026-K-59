#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 13: MariaDB Master-Slave Replication (yaga & inumaki)

TARGET="${1:-yaga}"

setup_yaga() {
    echo "[yaga] Mengonfigurasi MariaDB Master..."

    # 1. Atur IP statis yaga dan nameserver untuk instalasi paket
    ip addr flush dev eth0 2>/dev/null || true
    ip addr add 10.93.4.8/24 dev eth0
    ip link set eth0 up
    ip route replace default via 10.93.4.1 dev eth0 2>/dev/null || true
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # 2. Instalasi paket MariaDB Server & Client
    apt-get update -y
    apt-get install -y mariadb-server mariadb-client

    # 3. Konfigurasi MariaDB Master (bind-address, server-id, binary logging)
    cat << 'EOF' > /etc/mysql/mariadb.conf.d/50-server.cnf
[server]

[mysqld]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql

# Buka akses agar mendengarkan di seluruh interface jaringan
bind-address            = 0.0.0.0

# Konfigurasi Binary Logging untuk Replikasi Master
server-id               = 1
log-bin                 = mariadb-bin
binlog_format           = ROW
binlog_do_db            = db_shibuya_k59
EOF

    # 4. Restart layanan MariaDB
    service mariadb restart
    service mariadb status

    # 5. Inisialisasi Database, Tabel, dan User Privilege
    mariadb -u root << 'EOF'
CREATE DATABASE IF NOT EXISTS db_shibuya_k59;

USE db_shibuya_k59;

CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(50) NOT NULL,
    client_ip VARCHAR(50) NOT NULL,
    proxy_ip VARCHAR(50) NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User untuk replikasi Slave (inumaki)
CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'password_replica';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replica'@'%';

-- User aplikasi untuk seluruh node di Network 4 (10.93.4.%)
CREATE USER IF NOT EXISTS 'jujutsu_user'@'10.93.4.%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON db_shibuya_k59.* TO 'jujutsu_user'@'10.93.4.%';
CREATE USER IF NOT EXISTS 'jujutsu_user'@'%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON db_shibuya_k59.* TO 'jujutsu_user'@'%';

FLUSH PRIVILEGES;
EOF

    echo "Konfigurasi DB Master yaga selesai."
    mariadb -u root -e "SHOW MASTER STATUS\G"
}

setup_inumaki() {
    echo "[inumaki] Mengonfigurasi MariaDB Slave..."

    # 1. Atur IP statis inumaki dan nameserver untuk instalasi paket
    ip addr flush dev eth0 2>/dev/null || true
    ip addr add 10.93.4.9/24 dev eth0
    ip link set eth0 up
    ip route replace default via 10.93.4.1 dev eth0 2>/dev/null || true
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # 2. Instalasi paket MariaDB Server & Client
    apt-get update -y
    apt-get install -y mariadb-server mariadb-client

    # 3. Konfigurasi MariaDB Slave (bind-address, server-id)
    cat << 'EOF' > /etc/mysql/mariadb.conf.d/50-server.cnf
[server]

[mysqld]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql

bind-address            = 0.0.0.0

# Konfigurasi Replikasi Slave
server-id               = 2
replicate_do_db         = db_shibuya_k59

[client]
ssl = 0
EOF

    # 4. Restart layanan MariaDB
    service mariadb restart
    service mariadb status

    # 5. Ambil posisi log dari Master yaga (10.93.4.8) secara otomatis
    echo "Mengambil status binlog dari Master yaga (10.93.4.8)..."
    MASTER_STATUS=$(mariadb -h 10.93.4.8 -u replica -ppassword_replica --skip-ssl -e "SHOW MASTER STATUS\G" 2>/dev/null)
    LOG_FILE=$(echo "$MASTER_STATUS" | grep -i "File:" | awk '{print $2}')
    LOG_POS=$(echo "$MASTER_STATUS" | grep -i "Position:" | awk '{print $2}')

    if [ -z "$LOG_FILE" ] || [ -z "$LOG_POS" ]; then
        echo "Peringatan: Gagal mengambil binlog otomatis. Menggunakan default posisi awal."
        LOG_FILE="mariadb-bin.000001"
        LOG_POS=4
    fi

    echo "Master Log File: $LOG_FILE"
    echo "Master Log Position: $LOG_POS"

    # 6. Hubungkan Slave ke Master yaga (Gunakan MASTER_SSL=0 untuk mencegah error sertifikat)
    mariadb -u root --skip-ssl << EOF
STOP SLAVE;
CHANGE MASTER TO
    MASTER_HOST='10.93.4.8',
    MASTER_USER='replica',
    MASTER_PASSWORD='password_replica',
    MASTER_PORT=3306,
    MASTER_LOG_FILE='$LOG_FILE',
    MASTER_LOG_POS=$LOG_POS,
    MASTER_CONNECT_RETRY=10,
    MASTER_SSL=0;
START SLAVE;
EOF

    echo "Konfigurasi DB Slave inumaki selesai."
}

case "$TARGET" in
    yaga)
        setup_yaga
        ;;
    inumaki)
        setup_inumaki
        ;;
    *)
        echo "Penggunaan: $0 {yaga|inumaki}"
        exit 1
        ;;
esac
