#!/bin/bash

setenforce 0

until dnf install -y \
tar \
wget \
git \
rsync \
httpd
do
    sleep 15
done

rm -rf /tmp/team4pro

cat > /root/.netrc << NETRC
machine github.com
login ${github_user}
password ${github_token}
NETRC

chmod 600 /root/.netrc

for i in $(seq 1 10)
do

    git clone \
        --depth 1 \
        --branch "${github_branch}" \
        "${github_repo}" \
        /tmp/team4pro && break

    rm -rf /tmp/team4pro

    sleep 10

done

rm -f /root/.netrc

if [ ! -d /tmp/team4pro ]; then

    echo "$(date) - GitHub Clone FAILED" \
    >> /var/log/team4-web-deploy.log

    exit 1

fi

find /var/www/html \
    -mindepth 1 \
    -maxdepth 1 \
    -exec rm -rf {} +

rsync -a \
    --delete \
    --exclude='.git/' \
    --exclude='.github/' \
    --exclude='.env' \
    --exclude='.env.example' \
    --exclude='*.php' \
    --exclude='config/' \
    --exclude='sql/' \
    --exclude='backend/' \
    --exclude='api/' \
    /tmp/team4pro/ \
    /var/www/html/

echo "$HOSTNAME" > /var/www/html/health.html

cat > /etc/httpd/conf.d/proxy-was.conf << EOF
ProxyPreserveHost On
RewriteEngine On
RewriteRule ^/health\.html\$ - [L]
RewriteRule ^/\$ http://${waslbip}/ [P,L]
RewriteRule ^/(.*\.php)\$ http://${waslbip}/\$1 [P,L]
RewriteCond %%{DOCUMENT_ROOT}%%{REQUEST_URI} !-f
RewriteCond %%{DOCUMENT_ROOT}%%{REQUEST_URI} !-d
RewriteRule ^/(.*)\$ http://${waslbip}/\$1 [P,L]
EOF

chown -R apache:apache /var/www/html

if ! httpd -t
then

    echo "$(date) - Apache configuration FAILED" \
    >> /var/log/team4-web-deploy.log

    exit 1

fi

systemctl enable --now httpd

echo "$(date) - Team4 WEB deployment completed" \
>> /var/log/team4-web-deploy.log

exit 0