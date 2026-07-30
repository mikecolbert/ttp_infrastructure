# ################ Set up environment for shared vars #####################
set -eu pipefail # Enable strict error handling
SCRIPT_DIR="$(cd "/cluster-src/scripts" && pwd)"
RELATIVE_PATH="${SCRIPT_DIR}/.."
REPO_PATH=$(realpath "$RELATIVE_PATH")
# ############### END Set up environment ##################################

echo "Renewing Let's Encrypt certificates"
# cd "${REPO_PATH}/containers/web-servers/"
cd "/cluster-src/containers/web-servers/"
docker compose run --rm certbot renew --webroot --webroot-path /var/www/certbot/

echo "Reloading NGINX to pick up any renewed certificates"
docker compose exec -t nginx nginx -s reload

echo "Certificate renewal check done"