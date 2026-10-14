#!/bin/bash

# PRAKTIKUM JARINGAN KOMPUTER 2026 - MODUL 3
# TESTING SOAL NOMOR 13: MariaDB Master-Slave Testing

TARGET="${1:-$(hostname)}"

test_yaga() {
    echo "TESTING SOAL 13: NODE yaga (DB Master)"

    echo -e "\n[1] Menambahkan Data Log Uji Coba ke Master (yaga):"
    mariadb -u root db_shibuya_k59 << 'EOF'
INSERT INTO request_logs (worker_name, client_ip, proxy_ip, user_agent)
VALUES ('yaga_master_test', '10.93.2.11', '10.93.1.4', 'Testing MariaDB Master-Slave Shibuya');
EOF

    echo "Data berhasil dimasukkan ke Master."

    echo -e "\n[2] Isi Tabel request_logs pada yaga (Master):"
    mariadb -u root -e "SELECT * FROM db_shibuya_k59.request_logs;"
}

test_inumaki() {
    echo "TESTING SOAL 13: NODE inumaki (Status Replikasi Slave)"

    echo -e "\n[1] Pengecekan Status Replikasi (Slave_IO & Slave_SQL):"
    mariadb -u root -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_IO_Error|Last_SQL_Error"

    echo -e "\n[2] Isi Tabel request_logs Saat Ini pada inumaki (Slave):"
    mariadb -u root -e "SELECT * FROM db_shibuya_k59.request_logs;" 2>/dev/null || echo "Tabel belum ada atau belum tersinkronisasi."
}

case "$TARGET" in
    yaga)
        test_yaga
        ;;
    inumaki)
        test_inumaki
        ;;
    *)
        echo "Menjalankan testing untuk target: $TARGET"
        if [ "$TARGET" = "yaga" ]; then
            test_yaga
        else
            test_inumaki
        fi
        ;;
esac
