#!/bin/bash
if [ `id -u` != 0 ]
then
	echo '请使用 root 用户运行'
	exit 1
fi
if [ `uname -m` != 'x86_64' ]
then
	echo '暂时只支持 x86_64 平台'
	exit 1
fi
pushd ~
echo '下载 Caddy 中...'
wget -O caddy_v1.0.4_linux_amd64_custom.tar.gz 'https://caddyserver.com/download/linux/amd64?plugins=http.forwardproxy&license=personal&telemetry=off' || {
	echo '下载 Caddy 失败'
	exit 1
}
echo '解压 Caddy 中...'
mkdir caddy
pushd caddy
tar xf ../caddy_v1.0.4_linux_amd64_custom.tar.gz
echo '安装 Caddy 中...'
cp caddy /usr/local/bin
chown root:root /usr/local/bin/caddy
chmod 755 /usr/local/bin/caddy
apt update
yes | apt install libcap2-bin
setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
mkdir /etc/caddy
chown -R root:root /etc/caddy
mkdir /etc/ssl/caddy
chown -R root:www-data /etc/ssl/caddy
chmod 0770 /etc/ssl/caddy
read -p '请输入域名：' domain
read -p '请输入邮箱：' email
cat > Caddyfile << EOF
http://$domain {
	forwardproxy {
		hide_ip
		hide_via
	}
	tls $email {
		protocols tls1.2 tls1.3
		ciphers ECDHE-ECDSA-AES128-GCM-SHA256 ECDHE-ECDSA-WITH-CHACHA20-POLY1305 ECDHE-ECDSA-AES256-GCM-SHA384
		key_type p256
		must_staple
	}
}
EOF
cp Caddyfile /etc/caddy/
chown root:root /etc/caddy/Caddyfile
chmod 644 /etc/caddy/Caddyfile
mkdir /var/www
chown www-data:www-data /var/www
chmod 555 /var/www
cp init/linux-systemd/caddy.service /etc/systemd/system/
chown root:root /etc/systemd/system/caddy.service
chmod 644 /etc/systemd/system/caddy.service
systemctl daemon-reload
systemctl start caddy.service
systemctl enable caddy.service
popd
popd
echo '安装结束，请自行根据报错和使用情况判断成功了没有'
