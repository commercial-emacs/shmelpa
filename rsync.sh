ROOT=$(git rev-parse --show-toplevel)
BITNAMI="bitnami@3.140.98.146"
rsync -azSHe ssh archive-contents.sh archive-contents.el $BITNAMI:/opt/bitnami/nginx/html/packages/melpa/
rsync -azSHe ssh crontab $BITNAMI:
rsync -azSHe ssh pipe.php $BITNAMI:/opt/bitnami/nginx/html/
rsync -azSHe ssh nginx.conf $BITNAMI:/opt/bitnami/nginx/conf/
