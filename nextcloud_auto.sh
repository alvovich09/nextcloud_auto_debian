#!/bin/bash

#Добавляем репозиторий Bullseye

echo -e "#Debian 11 (Bullseye)

deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free" >> ./sources.list

#Устанавливаем бд mariadb
sudo apt install mariadb-server -y
sudo systemctl enable mariadb
sudo systemctl start mariadb

#Сбор данных для создания БД
echo -n "Введите пароль для администратора базы данных: "
read password_base
echo "password_base = $password_base" >> /home/debian/info.txt

echo -n "Введите имя базы данных для создания: "
read name_base
echo "name_base = $name_base" >> /home/debian/info.txt

echo -n "Введите имя пользователя  для базы данных: "
read name_user_base
echo "name_user_base = $name_user_base" >> /home/debian/info.txt

echo -n "Введите пароль для пользователя созданного выше: "
read password_user_base
echo "password_user_base = $password_user_base" >> /home/debian/info.txt

#Создание базы для Nextcloud
sudo mysql -u root -p $password_base -e "CREATE DATABASE $name_base DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
sudo mysql -u root -p $password_base -e "GRANT ALL PRIVILEGES ON $name_base.* TO $name_user_base@localhost IDENTIFIED BY '$password_user_base';"
