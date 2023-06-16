sudo apt update -yq
sudo apt install -yq emacs rsync xauth pandoc python3-pip
sudo apt install -yq make mysql-server
sudo systemctl start mysql.service
sudo python3 -m pip install mysql-connector-python stripe
git clone -depth 1 https://github.com/melpa/melpa.git
mv ~/stack/nginx/html/index.html ~/stack/nginx/html/index.html.orig
# git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server
composer require stripe/stripe-php
sudo chsh git --shell /usr/bin/bash
# install gitolite
# install golang
# install nodejs
echo "export PATH=/usr/local/go/bin:\$PATH" >> ~/.bashrc
echo "export PATH=/usr/local/lib/nodejs/node-v18.14.2-linux-x64/bin:~/go/bin:\$PATH" >> ~/.bashrc
