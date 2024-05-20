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

#Настраиваем и устанавливаем БД

echo -n "Введите имя базы данных для создания: "
read name_base
echo "name_base = $name_base" >> /home/debian/info.txt
mysql -u root -e "CREATE DATABASE $name_base DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
echo "БД создана!"

echo -n "Введите имя пользователя  для базы данных: "
read  name_user_base
echo -n "Введите пароль для пользователя созданного выше. Пароль будет скрыт: "
read -s password_user_base
echo "name_user_base = $name_user_base" >> /home/debian/info.txt
echo "password_user_base = $password_user_base" >> /home/debian/info.txt
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
sudo -y install php8.3
#Устанавливаем дополнительные модули для взаимодействия PHP-Nextcloud
sudo apt install libapache2-mod-php php-gd php-mysql php-curl php-mbstring php-intl php-gmp php-bcmath php-xml php-imagick php-zip

#Установка и настройка nginx

sudo apt install nginx -y
