#!/bin/sh

uci set 'network.lan.ipv6=0'
uci set 'network.wan.ipv6=0'
uci set network.lan.delegate="0"

uci set 'dhcp.lan.dhcpv6=disabled'
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra

uci -q delete network.globals.ula_prefix

/etc/init.d/odhcpd disable
/etc/init.d/odhcpd stop

uci set dhcp.@dnsmasq[0].filter_aaaa='1'

uci commit

service dnsmasq restart

sysctl -w net.ipv6.conf.all.disable_ipv6=1
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sleep 5

# 1. Поиск всех установленных пакетов, связанных с IPv6
IPV6_PACKAGES=$(opkg list-installed | awk '{print $1}' | grep -E 'ipv6|dhcp6|6in4|6to4|6rd|odhcpd|odhcp6c|nat64|tayga|jool')

if [ -z "$IPV6_PACKAGES" ]; then
    echo "Компоненты IPv6 не найдены."
    exit 0
fi

echo "Найдены следующие пакеты для удаления:"
echo "$IPV6_PACKAGES"
echo "----------------------------------------"

# 2. Удаление найденных пакетов с игнорированием зависимостей (--force-depends)
for pkg in $IPV6_PACKAGES; do
    echo "Удаление $pkg..."
    opkg remove --force-depends "$pkg"
done

# 3. Очистка системного кеша пакетов
rm -rf /var/opkg-lists/*

echo "----------------------------------------"
echo "Удаление завершено."

# 4. Интерактивный запрос на перезагрузку роутера
printf "Перезагрузить роутер? (y/n): "
read -r response

if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    echo "Перезагрузка..."
    reboot
else
    echo "Перезагрузка отменена. Не забудьте перезагрузить устройство позже вручную."
fi


# /etc/init.d/network restart
