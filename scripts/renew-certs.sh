set -eu pipefail # Enable strict error handling

echo "Renewing Let's Encrypt certificates"
cd "/cluster-src/containers/web-servers/"
docker compose run --rm certbot renew --webroot --webroot-path /var/www/certbot/

echo "Reloading NGINX to pick up any renewed certificates"
docker compose exec -t nginx nginx -s reload

echo "Certificate renewal check done"