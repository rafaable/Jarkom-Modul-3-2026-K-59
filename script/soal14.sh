#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# SOAL NOMOR 14: Backend Workers (Frontend: maki, panda; API: nanami, todo, kirara)

NODE_NAME="${1:-$(hostname)}"

setup_frontend() {
    local node="$1"
    local ip="$2"
    echo "[$node] Mengonfigurasi Frontend Worker ($ip)..."

    ip addr flush dev eth0 2>/dev/null || true
    ip addr add ${ip}/24 dev eth0
    ip link set eth0 up
    ip route replace default via 10.93.4.1 dev eth0 2>/dev/null || true
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    apt-get update -y
    apt-get install -y nginx php-fpm

    PHP_VERSION=$(php -v 2>/dev/null | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2)
    [ -z "$PHP_VERSION" ] && PHP_VERSION="8.4"
    PHP_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"

    service "php${PHP_VERSION}-fpm" start 2>/dev/null || service php-fpm start 2>/dev/null

    cat << 'EOF' > /var/www/html/index.php
<?php
$hostname = gethostname();
echo "Hello from Frontend Worker: " . $hostname . "\n";
?>
EOF
    chown -R www-data:www-data /var/www/html

    cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html;
    server_name jujutsu.k59.com www.jujutsu.k59.com _;

    # Access Control: Hanya izinkan proxy gojo (10.93.1.4)
    allow 10.93.1.4;
    allow 127.0.0.1;
    deny all;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF

    nginx -t
    service nginx restart
    service "php${PHP_VERSION}-fpm" restart 2>/dev/null || service php-fpm restart 2>/dev/null
    echo "Frontend Worker $node ($ip) siap."
}

setup_api() {
    local node="$1"
    local ip="$2"
    echo "[$node] Mengonfigurasi API Worker ($ip)..."

    ip addr flush dev eth0 2>/dev/null || true
    ip addr add ${ip}/24 dev eth0
    ip link set eth0 up
    ip route replace default via 10.93.4.1 dev eth0 2>/dev/null || true
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    apt-get update -y
    apt-get install -y nginx php-fpm php-mysqli mariadb-client

    PHP_VERSION=$(php -v 2>/dev/null | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2)
    [ -z "$PHP_VERSION" ] && PHP_VERSION="8.4"
    PHP_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"

    service "php${PHP_VERSION}-fpm" start 2>/dev/null || service php-fpm start 2>/dev/null

    cat << 'EOF' > /var/www/html/index.php
<?php
header('Content-Type: application/json; charset=utf-8');

$worker = gethostname();
$client_ip = isset($_SERVER['HTTP_X_REAL_IP']) ? $_SERVER['HTTP_X_REAL_IP'] : 
             (isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : $_SERVER['REMOTE_ADDR']);
$proxy_ip = $_SERVER['REMOTE_ADDR'];
$user_agent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : 'Unknown';

$conn = new mysqli('10.93.4.8', 'jujutsu_user', 'password123', 'db_shibuya_k59');
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit;
}

$stmt = $conn->prepare("INSERT INTO request_logs (worker_name, client_ip, proxy_ip, user_agent) VALUES (?, ?, ?, ?)");
if ($stmt) {
    $stmt->bind_param("ssss", $worker, $client_ip, $proxy_ip, $user_agent);
    $stmt->execute();
    $stmt->close();
}
$conn->close();

echo json_encode([
    "status" => "success",
    "worker" => $worker,
    "client_ip" => $client_ip,
    "proxy_ip" => $proxy_ip,
    "message" => "Request logged successfully to yaga"
]) . "\n";
?>
EOF
    chown -R www-data:www-data /var/www/html

    cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html;
    server_name jujutsu.k59.com www.jujutsu.k59.com _;

    # Access Control: Hanya izinkan internal load balancer geto (10.93.4.2)
    allow 10.93.4.2;
    allow 127.0.0.1;
    deny all;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF

    nginx -t
    service nginx restart
    service "php${PHP_VERSION}-fpm" restart 2>/dev/null || service php-fpm restart 2>/dev/null
    echo "API Worker $node ($ip) siap."
}

case "$NODE_NAME" in
    maki)
        setup_frontend "maki" "10.93.4.3"
        ;;
    panda)
        setup_frontend "panda" "10.93.4.4"
        ;;
    nanami)
        setup_api "nanami" "10.93.4.5"
        ;;
    todo)
        setup_api "todo" "10.93.4.6"
        ;;
    kirara)
        setup_api "kirara" "10.93.4.7"
        ;;
    *)
        echo "Penggunaan: $0 {maki|panda|nanami|todo|kirara}"
        exit 1
        ;;
esac
