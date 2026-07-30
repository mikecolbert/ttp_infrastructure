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


${REPO_PATH}/scripts/update-images.sh
${REPO_PATH}/scripts/update-source.sh
${REPO_PATH}/scripts/build_containers.sh