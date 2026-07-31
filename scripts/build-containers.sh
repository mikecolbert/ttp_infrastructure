echo "Building containers"

set -eu pipefail # Enable strict error handling

echo "Building base images"
cd /cluster-src/containers/base-images
docker compose build linux-base
docker compose build python-base
echo "base images done"

echo "Build core app"
cd /cluster-src/containers/core-app
docker compose build
echo "core app done"

echo "Building nginx server"
cd /cluster-src/containers/web-servers
docker compose build
echo "nginx server done"


echo "Restart containers (if needed)"
cd /cluster-src/containers/core-app
docker compose up -d --remove-orphans
cd /cluster-src/containers/web-servers
docker compose up -d nginx --remove-orphans
echo "restarts done."