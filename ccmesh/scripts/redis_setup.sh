# on 10.10.1.1
sed -i 's/bind 127.0.0.1 -::1//g' /etc/redis/redis.conf
service redis-server restart
echo "CONFIG SET protected-mode no" | redis-cli