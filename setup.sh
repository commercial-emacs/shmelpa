sudo apt update -yq
sudo apt install -yq emacs rsync xauth pandoc
git clone -depth 1 https://github.com/melpa/melpa.git
mv ~/stack/nginx/html/index.html ~/stack/nginx/html/index.html.orig 
