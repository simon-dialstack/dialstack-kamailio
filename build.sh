#!/bin/bash
set -e

IMAGE_NAME="dialstack-kamailio"
IMAGE_TAG="${1:-latest}"

echo "Building $IMAGE_NAME:$IMAGE_TAG..."
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

echo "Build complete!"
