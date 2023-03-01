ROOT=$(git rev-parse --show-toplevel)
BITNAMI="bitnami@3.140.98.146"
rsync -azSHe ssh redoctor-contents.sh check-contents.sh archive-contents.sh archive-contents.el $BITNAMI:/opt/bitnami/nginx/html/packages/melpa/
rsync -azSHe ssh crontab $BITNAMI:
rsync -azSHe ssh pipe.php hooks.php $BITNAMI:/opt/bitnami/nginx/html/
rsync -azSHe ssh ../sls_commercial/docker/key_to_account.py $BITNAMI:/opt/bitnami/nginx/html/
rsync -azSHe ssh nginx.conf $BITNAMI:/opt/bitnami/nginx/conf/
ssh $BITNAMI sudo /opt/bitnami/ctlscript.sh restart nginx
