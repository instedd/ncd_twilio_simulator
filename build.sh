#!/bin/bash
set -eo pipefail

# This will load the script from this repository. Make sure to point to a specific commit so the build continues to work
# event if breaking changes are introduced in this repository
source <(curl -s https://raw.githubusercontent.com/manastech/ci-docker-builder/a2d44f8b7f155afe5a9652252cfb262871846a41/build.sh)

# Prepare the build
dockerSetup

# Write a VERSION file for the footer
echo $VERSION > VERSION

# Build and push the Docker image
dockerBuildAndPush
