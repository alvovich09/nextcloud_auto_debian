#!/bin/bash

#Обновляем пакеты ОС
sudo apt update&& apt upgrade -y

#Добавляем репозиторий Bullseye

echo -e "#Debian 11 (Bullseye)

deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free" >> ./sources.list

#Устанавливаем БД mariadb
sudo apt install mariadb-server -y
sudo systemctl enable mariadb
sudo systemctl start mariadb

#Настраиваем БД

echo -n "Введите имя базы данных для создания: "
read name_base
echo "name_base = $name_base" >> /home/debian/db_nextcloud_info.txt
mysql -u root -e "CREATE DATABASE $name_base DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
echo "БД создана!"

echo -n "Введите имя пользователя  для базы данных: "
read  name_user_base
echo -n "Введите пароль для пользователя созданного выше. Пароль будет скрыт: "
read -s password_user_base
echo "name_user_base = $name_user_base" >> /home/debian/db_nextcloud_info.txt
echo "password_user_base = $password_user_base" >> /home/debian/db_nextcloud_info.txt
mysql -u root -e "CREATE USER ${name_user_base}@localhost IDENTIFIED BY '$password_user_base';"
echo "Пользователь создан!"

echo "Раздача всех прав пользователю на созданную базу данных"
mysql -u root -e "GRANT ALL PRIVILEGES ON $name_base.* TO $name_user_base@localhost IDENTIFIED BY '$password_user_base';"
mysql -u root -e "FLUSH PRIVILEGES;"
echo "БД готова для продолжения установки"

#Настраиваем репозиторий для установки. На момент создания скрипта, актуальный - 8.3

#Устанавливаем пакеты для использования репозиториев по https
sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2
#Добавляем репозиторий
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
#Для нового репозитория загружаем специальный ключ безопасности
wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
#Обновляем список пакетов
sudo apt update
#Устанавливаем php
sudo apt  install php8.3 -y
#Устанавливаем дополнительные модули для взаимодействия PHP-Nextcloud
sudo apt install libapache2-mod-php php-gd php-mysql php-curl php-mbstring php-intl php-gmp php-bcmath php-xml php-imagick php-zip -y
#Настройка php для nextcloud

PHP_WWW_CONF="/etc/php/8.3/fpm/pool.d/www.conf"

PATH_CONF="env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin"
HOSTNAME_CONF="env\[HOSTNAME\] = \$HOSTNAME"
TMP_CONF="env\[TMP\] = \/tmp"
TMPDIR_CONF="env\[TMPDIR\] = \/tmp"
TEMP_CONF="env\[TEMP\] = \/tmp"

sudo sed -i "s/;${PATH_CONF}/${PATH_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${HOSTNAME_CONF}/${HOSTNAME_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${TMP_CONF}/${TMP_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${TMPDIR_CONF}/${TMPDIR_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${TEMP_CONF}/${TEMP_CONF}/g" $PHP_WWW_CONF


STRING1="\;opcache.enable_cli=0"
STRING1_1="\;opcache.enable_cli=1"
STRING2="\;opcache.interned_strings_buffer=8"
STRING2_2="\;opcache.interned_strings_buffer=32"
STRING3="\;opcache.revalidate_freq=2"
STRING3_1="\;opcache.revalidate_freq=1"
PHP_INI="/etc/php/8.3/fpm/php.ini"

sudo sed -i "s/$STRING1/$STRING1_1/g" $PHP_INI
sudo sed -i "s/$STRING2/$STRING2_2/g" $PHP_INI
sudo sed -i "s/$STRING3/$STRING3_1/g" $PHP_INI

sudo systemctl enable php8.3-fpm
sudo systemctl restart php8.3-fpm

#Установка и настройка nginx

sudo apt install nginx -y
