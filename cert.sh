BITNAMI="bitnami@3.140.98.146"
DOMAIN=commandlinesystems.com
WILDCARD=*.$DOMAIN
pip3 install certbot certbot-dns-route53
mkdir -p ./cert/log ./cert/config ./cert/work
cd ./cert
certbot certonly -n --register-unsafely-without-email -d $DOMAIN -d $WILDCARD --dns-route53 --logs-dir ./log --config-dir ./config --work-dir ./work --agree-tos
rsync -vaLzSHe ssh ./config/live/commandlinesystems.com/privkey.pem $BITNAMI:/opt/bitnami/nginx/conf/bitnami/certs/server.key
rsync -vaLzSHe ssh ./config/live/commandlinesystems.com/fullchain.pem $BITNAMI:/opt/bitnami/nginx/conf/bitnami/certs/server.crt

# the above also *renews* the cert, after which,
# sudo /opt/bitnami/ctlscript.sh restart nginx
