#!/bin/bash

LOG=/var/log/team4-was-deploy.log

log() {
    echo "$(date '+%F %T') | $*" >> "$LOG"
}

run_sql() {
    local host="$1"; shift
    local out rc
    out=$(mysql -h "$host" -u "$U" -p"$P" -e "$*" 2>&1)
    rc=$?
    if [ $rc -ne 0 ]; then
        log "SQL FAILED ($host) rc=$rc : $(echo "$out" | head -3 | tr '\n' ' ')"
    fi
    return $rc
}

log "===== WAS 배포 시작 ====="
setenforce 0 2>/dev/null
log "SELinux 비활성화"

until dnf install -y epel-release && \
dnf install -y \
tar \
wget \
unzip \
git \
rsync \
httpd \
php \
php-fpm \
php-gd \
php-mysqlnd \
php-pecl-redis \
mysql
do
    log "패키지 설치 재시도"
    sleep 15
done

log "패키지 설치 완료"

sed -i \
's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' \
/etc/httpd/conf/httpd.conf

rm -rf /tmp/team4pro

export GIT_TERMINAL_PROMPT=0

GH_URL=$(echo "${github_repo}" \
  | sed "s#https://#https://${github_user}:${github_token}@#")

for i in $(seq 1 10)
do
    if git clone --depth 1 --branch "${github_branch}" "$GH_URL" /tmp/team4pro \
       >> "$LOG" 2>&1
    then
        log "GitHub Clone 성공 (시도 $i회)"
        break
    fi

    log "GitHub Clone 실패 (시도 $i회)"
    rm -rf /tmp/team4pro
    sleep 10
done

unset GH_URL


if [ ! -d /tmp/team4pro ]; then
    log "GitHub Clone 최종 실패 - 배포 중단"
    exit 1
fi

find /var/www/html -mindepth 1 -maxdepth 1 -exec rm -rf {} +

rsync -a \
--exclude='.git/' \
--exclude='.github/' \
--exclude='.env' \
/tmp/team4pro/ \
/var/www/html/

rm -rf /tmp/team4pro

log "웹소스 배포 완료 : $(ls /var/www/html | wc -l) 개 항목"

cat > /var/www/html/.env << ENV
DB_HOST=${onprem_mysql_host}
DB_PORT=3306

DB_NAME=${app_db_name}
DB_USER=${app_db_user}
DB_PASSWORD=${mysql_admin_password}

AZURE_DB_HOST=${azure_mysql_fqdn}
AZURE_DB_PORT=3306
ENV

chown root:apache /var/www/html/.env
chmod 640 /var/www/html/.env

log ".env 생성 완료"

echo '<?php http_response_code(200); echo "OK";' \
> /var/www/html/health.php
chown -R apache:apache /var/www/html
chown root:apache /var/www/html/.env
chmod 640 /var/www/html/.env
cat > /etc/php.d/99-redis-session.ini << PHPINI
session.save_handler = redis
session.save_path = "tls://${redis_host}:${redis_port}?auth=${redis_key}"
PHPINI

log "Redis 세션 설정 작성"

systemctl enable --now php-fpm httpd >> "$LOG" 2>&1

if php -r 'session_start(); $_SESSION["probe"]=1; session_write_close();' \
   >> "$LOG" 2>&1
then
    log "Redis 세션 동작 확인 OK"
else
    log "Redis 세션 동작 실패 - 로컬 파일 세션으로 폴백됨 (save_path/TLS 확인 필요)"
fi

O=${onprem_mysql_host}
A=${azure_mysql_fqdn}
U=${mysql_admin_username}
P=${mysql_admin_password}
D=${app_db_name}

ONPREM_UP=0

for i in $(seq 1 90)
do
    if mysqladmin ping -h "$O" -u "$U" -p"$P" --connect-timeout=5 &>/dev/null
    then
        ONPREM_UP=1
        log "On-Prem MySQL 연결 확인 (대기 $((i*10))초)"
        break
    fi
    sleep 10
done

if [ "$ONPREM_UP" -eq 0 ]; then
    log "On-Prem MySQL 연결 실패 (15분 경과) - 복제 구성 건너뜀"
fi

SOURCE_TABLES=0

if [ "$ONPREM_UP" -eq 1 ]; then

    SOURCE_TABLES=$(mysql -h "$O" -u "$U" -p"$P" -Nse \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$D';" \
        2>>"$LOG")
    SOURCE_TABLES=$${SOURCE_TABLES:-0}

    log "On-Prem $D 테이블 수 : $SOURCE_TABLES"


    if [ "$SOURCE_TABLES" -eq 0 ] && [ -f /var/www/html/sql/init.sql ]; then

        if mysql -h "$O" -u "$U" -p"$P" < /var/www/html/sql/init.sql >> "$LOG" 2>&1
        then
            log "sql/init.sql 적용 성공"
        else
            log "sql/init.sql 적용 실패 - On-Prem 계정 권한 확인 필요"
            log "  필요 권한 : GRANT ALL PRIVILEGES ON *.* TO '$U'@'%'"
        fi

        SOURCE_TABLES=$(mysql -h "$O" -u "$U" -p"$P" -Nse \
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$D';" \
            2>>"$LOG")
        SOURCE_TABLES=$${SOURCE_TABLES:-0}

        log "적용 후 On-Prem $D 테이블 수 : $SOURCE_TABLES"
    fi

    if [ "$SOURCE_TABLES" -gt 0 ]; then
        if run_sql "$O" "
            CREATE USER IF NOT EXISTS '${app_db_user}'@'%' IDENTIFIED BY '$P';
            ALTER USER '${app_db_user}'@'%' IDENTIFIED BY '$P';
            GRANT ALL PRIVILEGES ON \`$D\`.* TO '${app_db_user}'@'%';
            FLUSH PRIVILEGES;"
        then
            log "On-Prem ${app_db_user} 계정 확인/생성 완료"
        fi
    fi
fi

if [ "$SOURCE_TABLES" -eq 0 ]; then

    log "복제 건너뜀 : On-Prem $D 에 테이블이 없음"

else

    REPL=$(mysql -h "$A" -u "$U" -p"$P" -e "SHOW SLAVE STATUS\G" 2>>"$LOG")

    if echo "$REPL" | grep -q "Slave_IO_Running: Yes" && \
       echo "$REPL" | grep -q "Slave_SQL_Running: Yes"
    then
        log "복제 이미 정상 동작 중 - 재설정 건너뜀"
    else

        log "복제 재설정 시작"

        run_sql "$A" "CALL mysql.az_replication_stop;"
        run_sql "$A" "CALL mysql.az_replication_remove_master;"

        DUMP=/tmp/team4-$D.sql

        if mysqldump -h "$O" -u "$U" -p"$P" \
            --single-transaction \
            --master-data=2 \
            --set-gtid-purged=OFF \
            --no-tablespaces \
            "$D" > "$DUMP" 2>>"$LOG"
        then
            log "mysqldump 성공 ($(wc -l < "$DUMP") 줄)"
        else
            log "mysqldump 실패 - On-Prem 계정 권한 확인 필요"
        fi

        read F G < <(
            sed -n \
            "s/.*MASTER_LOG_FILE='\([^']*\)', MASTER_LOG_POS=\([0-9]*\).*/\1 \2/p" \
            "$DUMP" | head -n 1
        )

        if [ -n "$F" ] && [ -n "$G" ]; then

            log "binlog 위치 : $F / $G"

            run_sql "$A" "CREATE DATABASE IF NOT EXISTS \`$D\`
                          CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

            if mysql -h "$A" -u "$U" -p"$P" "$D" < "$DUMP" >> "$LOG" 2>&1
            then
                log "Azure $D 초기 데이터 적재 완료"
            else
                log "Azure $D 데이터 적재 실패"
            fi

            if run_sql "$A" "
                CREATE USER IF NOT EXISTS '${app_db_user}'@'%' IDENTIFIED BY '$P';
                ALTER USER '${app_db_user}'@'%' IDENTIFIED BY '$P';
                GRANT ALL PRIVILEGES ON \`$D\`.* TO '${app_db_user}'@'%';"
            then
                log "Azure ${app_db_user} 계정 확인/생성 완료"
            fi

            if run_sql "$A" "
                CALL mysql.az_replication_change_master('$O','$U','$P',3306,'$F',$G,'');
                CALL mysql.az_replication_start;"
            then
                log "복제 시작 명령 실행 완료"
            fi

        else
            log "복제 실패 : binlog 위치를 찾지 못함"
        fi

        rm -f "$DUMP"
    fi

    sleep 5
    REPL=$(mysql -h "$A" -u "$U" -p"$P" -e "SHOW SLAVE STATUS\G" 2>>"$LOG")
    IO=$(echo "$REPL"  | grep -oP 'Slave_IO_Running: \K\w+'  | head -1)
    SQ=$(echo "$REPL"  | grep -oP 'Slave_SQL_Running: \K\w+' | head -1)
    log "복제 최종 상태 : IO=$${IO:-none} SQL=$${SQ:-none}"

    if [ "$IO" != "Yes" ]; then
        ERR=$(echo "$REPL" | grep -oP 'Last_IO_Error: \K.*' | head -1)
        [ -n "$ERR" ] && log "  Last_IO_Error : $ERR"
    fi
fi


cat > /etc/yum.repos.d/elastic.repo << REPO
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
REPO

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch >> "$LOG" 2>&1

until dnf install -y filebeat >> "$LOG" 2>&1
do
    log "filebeat 설치 재시도"
    sleep 15
done

filebeat modules enable apache >> "$LOG" 2>&1

cat > /etc/filebeat/modules.d/apache.yml << MODULE
- module: apache

  access:
    enabled: true
    var.paths:
      - "/var/log/httpd/access_log*"

  error:
    enabled: true
    var.paths:
      - "/var/log/httpd/error_log*"
MODULE

cat > /etc/filebeat/filebeat.yml << YML
filebeat.config.modules:
  path: /etc/filebeat/modules.d/*.yml
  reload.enabled: false


filebeat.inputs:

  - type: log
    enabled: true

    paths:
      - /var/log/php-fpm/*.log

    fields:
      log_source: php-fpm

    fields_under_root: true


output.logstash:
  hosts: ["${elk_ip}:5044"]
YML

systemctl enable --now filebeat >> "$LOG" 2>&1

if filebeat test output >> "$LOG" 2>&1; then
    log "Filebeat -> ELK(${elk_ip}:5044) 연결 확인 OK"
else
    log "Filebeat -> ELK 연결 실패 (VPN / 방화벽 5044 확인 필요)"
fi

log "----- 배포 요약 -----"
log "웹소스        : $([ -d /var/www/html/backend ] && echo OK || echo MISSING)"
log ".env          : $([ -f /var/www/html/.env ] && echo OK || echo MISSING)"
log "php redis 확장 : $(php -m | grep -q redis && echo OK || echo MISSING)"
log "httpd         : $(systemctl is-active httpd)"
log "php-fpm       : $(systemctl is-active php-fpm)"
log "filebeat      : $(systemctl is-active filebeat)"
log "===== WAS 배포 완료 ====="

exit 0