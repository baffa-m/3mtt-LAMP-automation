#!/bin/bash

# Variables
APP_DIR="/var/www/html/laravel-app"
GIT_REPO="https://github.com/laravel/laravel.git"
DB_NAME="laraveldb"
DB_USER="laraveluser"
DB_PASSWORD="password"

# Update package list and install required packages
sudo apt update
sudo apt install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https

# Install Apache web server
sudo apt install apache2 -y

# Install MySQL database server
sudo apt install mysql-server -y

# Secure MySQL installation
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Install PHP and required modules
sudo apt-add-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt install -y php8.3 libapache2-mod-php php8.3-{cli,pdo,mysql,zip,gd,mbstring,curl,xml,bcmath,common}
sudo apt install php-xml
sudo apt-get install -y unzip git

# Allow Apache to run on boot and restart the service
sudo systemctl enable apache2
sudo systemctl restart apache2

# Adjust Firewall
sudo ufw allow in "Apache Full"

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
echo "installed composer"

# Configure MySQL for Laravel
DB_EXISTS=$(mysql -u root -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME")
if [ -z "$DB_EXISTS" ]; then
    sudo mysql -e "CREATE DATABASE $DB_NAME;"
fi

USER_EXISTS=$(mysql -u root -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER');" | grep 1)
if [ -z "$USER_EXISTS" ]; then
    sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
fi
sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Clone Laravel application and set permissions
sudo rm -rf $APP_DIR
sudo git clone $GIT_REPO $APP_DIR
sudo git config --global --add safe.directory $APP_DIR

# Adjust ownership and permissions
sudo chown -R $USER:$USER $APP_DIR
sudo chmod -R 775 $APP_DIR/storage
sudo chmod -R 775 $APP_DIR/bootstrap/cache

echo "cd into folder"
# Install Laravel dependencies with Composer
cd $APP_DIR
composer install 2>/dev/null
echo "Dependency installation"

# Set up the .env file
sudo cp .env.example .env
sudo chmod -R 775 /var/www/html/laravel-app/.env
sed -i "s/^#\?DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
sed -i "s/^#\?# DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/^#\?# DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/^#\?# DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/^#\?# DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/^#\?# DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env

echo "set Environments"

sudo php artisan key:generate
sudo php artisan migrate

# Set permissions
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR/storage

# Configure Apache for Laravel
cat <<EOF | sudo tee /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>
    ServerAdmin admin@laravel.com
    ServerName laravel-app.local
    DocumentRoot $APP_DIR/public
    <Directory $APP_DIR/public>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo a2dissite 000-default
sudo a2ensite laravel.conf
sudo a2enmod rewrite
sudo systemctl reload apache2
echo "Laravel application has been deployed and configured successfully!"
