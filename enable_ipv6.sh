#!/bin/sh

echo "Включаем IPv6"
sleep 1

uci set 'network.lan.ipv6=1'
uci set 'network.wan.ipv6=1'
uci set network.lan.delegate="1"

uci set 'dhcp.lan.dhcpv6=server'
uci set 'dhcp.lan.ra=server'

# uci set network.globals.ula_prefix='fd...' # Раскомментируйте и укажите ваш префикс

/etc/init.d/odhcpd enable
/etc/init.d/odhcpd start

uci set dhcp.@dnsmasq[0].filter_aaaa='0'

uci commit

service dnsmasq restart

sysctl -w net.ipv6.conf.all.disable_ipv6=0
echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.lo.disable_ipv6=0

echo "----------------------------------------"
echo "Завершено."
sleep 1

echo "Перезапустить сеть сейчас? (y/n): "
read response < /dev/tty

if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    echo "Перезапуск..."
    /etc/init.d/network restart
else
    echo "Отменен. Не забудьте перезапустить сеть позже вручную."
fi
