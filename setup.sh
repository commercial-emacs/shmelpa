sudo apt update -yq
sudo apt install -yq emacs rsync xauth pandoc
git clone -depth 1 https://github.com/melpa/melpa.git
mv ~/stack/nginx/html/index.html ~/stack/nginx/html/index.html.orig
# git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server
