set -eu pipefail # Enable strict error handling

REPO_PATH=/cluster-src

${REPO_PATH}/scripts/update-images.sh
${REPO_PATH}/scripts/update-source.sh
${REPO_PATH}/scripts/build-containers.sh
${REPO_PATH}/scripts/renew-certs.sh
