echo "installing docker..."
sudo apt update && sudo apt install docker.io -y && sudo apt install docker-compose -y
echo "installing certbot"
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
echo "Do you want to use existing .env and docker-compose.yml files?"
echo
echo -e "Type \e[1;35m'Y/y'\e[0m and press ENTER to use existing .env and docker-compose.yml files"
echo -e "If you want to generate new .env and docker-compose.yml type any letter and press ENTER"
read INPUT
case "$INPUT" in
  "Y"|"y" )
  echo "Good bye!"
  ;;
  * )
  echo "Starting configuration..."
  echo -n > .env
  echo -n > docker-compose.yml
  CHECK=0
  echo -e "enter \e[1;34mdomain \e[0m "
  read DOMAIN_NAME
  echo -e "enter \e[1;34mMYSQL_USER\e[0m"
  read MYSQL_USER
  echo -e "enter \e[1;34mMYSQL_PASSWORD\e[0m"
  read MYSQL_PASSWORD
  echo -e "enter \e[1;34mMYSQL_ROOT_PASSWORD\e[0m"
  read MYSQL_ROOT_PASSWORD
  while [[ $CHECK -eq 0 ]]; do
    echo -e "Please check CAREFULLY if information is correct:

    domain               \e[1;31m $DOMAIN_NAME \e[0m
    MYSQL_USER           \e[1;31m $MYSQL_USER \e[0m
    MYSQL_PASSWORD       \e[1;31m $MYSQL_PASSWORD \e[0m
    MYSQL_ROOT_PASSWORD  \e[1;31m $MYSQL_ROOT_PASSWORD \e[0m"

    echo
    echo -e "Type \e[1;35m'Y/y'\e[0m and press ENTER if everything is OK to update .env file"
    echo -e "Type \e[1;35m'1'\e[0m and press ENTER to correct domain"
    echo -e "Type \e[1;35m'2'\e[0m and press ENTER to correct MYSQL_USER"
    echo -e "Type \e[1;35m'3'\e[0m and press ENTER to correct MYSQL_PASSWORD"
    echo -e "Type \e[1;35m'4'\e[0m and press ENTER to correct MYSQL_ROOT_PASSWORD"
    echo "Type any letter and press ENTER to skip"

    read REPLY
         case "$REPLY" in
           "Y"|"y" )
             echo "DOMAIN_NAME=$DOMAIN_NAME" >> .env
             echo "MYSQL_USER=$MYSQL_USER" >> .env
             echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> .env
             echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> .env
             CHECK=1
             ;;
           "1" )
             echo "enter domain"
             read DOMAIN_NAME
             CHECK=0
             ;;
           "2" )
             echo "enter MYSQL_USER"
             read MYSQL_USER
             CHECK=0
               ;;
           "3" )
             echo "enter MYSQL_PASSWORD"
             read MYSQL_PASSWORD
             CHECK=0
               ;;
           "4" )
             echo "enter MYSQL_ROOT_PASSWORD"
             read MYSQL_ROOT_PASSWORD
             CHECK=0
               ;;
            * )
             echo "Bye!"
             CHECK=1
             esac
  done
  echo -e "Do you want to issue SSL certificates? Type \e[1;35m'Y/y'\e[0m and press ENTER to proceed or type any letter and press ENTER to skip"
  read INPUT
  case "$INPUT" in
    "Y"|"y" )
    sudo certbot certonly --standalone --agree-tos --no-eff-email -d $DOMAIN_NAME -d www.$DOMAIN_NAME
    ;;
    * )
    echo "Let's generate docker-compose.yml!"
  esac

  echo "updating docker-compose.yml..."
  echo "
  version: '3'" >> docker-compose.yml
  echo '
  services:
    db:
      image: mysql:8.0
      container_name: db
      restart: unless-stopped
      env_file: .env
      environment:
        - MYSQL_DATABASE=wordpress
      volumes:
        - dbdata:/var/lib/mysql
      command: '--default-authentication-plugin=mysql_native_password'
      networks:
        - app-network

    wordpress:
      depends_on:
        - db
      image: wordpress:5.1.1-fpm-alpine
      container_name: wordpress
      restart: unless-stopped
      env_file: .env
      environment:
        - WORDPRESS_DB_HOST=db:3306
        - WORDPRESS_DB_USER=$MYSQL_USER
        - WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
        - WORDPRESS_DB_NAME=wordpress
      volumes:
        - wordpress:/var/www/html
      networks:
        - app-network

    webserver:
      depends_on:
        - wordpress
      image: nginx:1.15.12-alpine
      container_name: webserver
      restart: unless-stopped
      ports:
        - "80:80"
        - "443:443"
      volumes:
        - wordpress:/var/www/html
        - ./nginx-conf:/etc/nginx/conf.d
        - /etc/letsencrypt:/etc/letsencrypt
      networks:
        - app-network
  volumes:
    wordpress:
    dbdata:

  networks:
    app-network:
      driver: bridge' >> docker-compose.yml

esac

echo "Done!"
echo "Please check CAREFULLY docker-compose.yml"
cat docker-compose.yml
echo "Do you want docker-compose.yml up?"
echo -e "Type \e[1;35m'Y/y'\e[0m and press ENTER to accept or type any letter and press ENTER to exit"
read REPLY
case "$REPLY" in
  "Y"|"y" )
  docker-compose up
  ;;
  * )
  echo "Good bye!"
esac

