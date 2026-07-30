# ################ Set up environment for shared vars #####################
set -eu pipefail # Enable strict error handling
# Script's working directory
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "/cluster-src/scripts" && pwd)"
# echo "SCRIPT_DIR ${SCRIPT_DIR}"
# RELATIVE_PATH="${SCRIPT_DIR}/../../.."
RELATIVE_PATH="${SCRIPT_DIR}/.."
# echo "RELATIVE_PATH ${RELATIVE_PATH}"
# Repo cloned here
REPO_PATH=$(realpath "$RELATIVE_PATH")
# echo "REPO_PATH ${REPO_PATH}"
# ############### END Set up environment ##################################

echo "Updating infrastructure code"
cd /cluster-src
git pull
echo "infrastructure code done"

echo "Updating app code"
cd /cluster-src/containers/core-app/ttp-docker/src/ttp_app
git pull
echo "Application code done"

echo "Updating static files"
cp -r /cluster-src/containers/core-app/ttp-docker/src/ttp-app/static/* /cluster-data/nginx/static/the-temperature-project
echo "Static files done"