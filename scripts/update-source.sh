set -eu pipefail # Enable strict error handling

echo "Updating infrastructure code"
cd /cluster-src
git pull
echo "infrastructure code done"

echo "Updating app code"
cd /cluster-src/containers/core-app/ttp-docker/src/ttp_app
git pull
echo "Application code done"

echo "Updating sensor API code"
cd /cluster-src/containers/api/ttp-docker/src/ttp_sensor_api
git pull
echo "Sensor API code done"

echo "Updating static files"
cp -r /cluster-src/containers/core-app/ttp-docker/src/ttp_app/static/* /cluster-data/nginx/static/the-temperature-project
echo "Static files done"