# ################ Set up environment for shared vars #####################
set -eu pipefail # Enable strict error handling
# Script's working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELATIVE_PATH="${SCRIPT_DIR}/../../.."
# Repo cloned here
REPO_PATH=$(realpath "$RELATIVE_PATH")
# ############### END Set up environment ##################################

echo "Updating infrastructure code"
cd ${REPO_PATH}/book/
git pull
echo "infrastructure code done"

echo "Updating HTMX sample app code"
cd ${REPO_PATH}/containers/core-app/ttp-docker/src/ttp-app
git pull
echo "Application code done"

echo "Updating static files"
cp -r ${REPO_PATH}/containers/core-app/ttp-docker/src/ttp-app/static/* /cluster-data/nginx/static/the-temperature-project
echo "Static files done"