#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_IMAGE="${ISAAC_SIM_BASE_IMAGE:-nvcr.io/nvidia/isaac-sim:4.5.0}"
CONTAINER_NAME="${CONTAINER_NAME:-goodnav-isaac}"
WORKDIR_IN_CONTAINER="${WORKDIR_IN_CONTAINER:-/workspace/IAmGoodNavigator}"
DISPLAY_VALUE="${DISPLAY:-:0}"
ISAAC_DOCKER_HOME="${ISAAC_DOCKER_HOME:-$HOME/docker/isaac-sim}"
BUILD_WITH_TORCH="${BUILD_WITH_TORCH:-0}"
FORCE_BUILD="${FORCE_BUILD:-0}"
GPU_IDS="${GPU_IDS:-all}"
CPU_CORES="${CPU_CORES:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not available in PATH." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Error: docker daemon is not reachable. Check that Docker is running." >&2
  exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "Warning: nvidia-smi is not available on the host." >&2
  echo "Check the NVIDIA driver if Isaac Sim cannot start." >&2
fi

if [ "$BUILD_WITH_TORCH" = "1" ] || [ "$BUILD_WITH_TORCH" = "true" ]; then
  INSTALL_TORCH=true
  DEFAULT_IMAGE="goodnav-isaac:4.5.0-torch"
else
  INSTALL_TORCH=false
  DEFAULT_IMAGE="goodnav-isaac:4.5.0"
fi

IMAGE="${GOODNAV_IMAGE:-$DEFAULT_IMAGE}"

if [ "$FORCE_BUILD" = "1" ] || [ "$FORCE_BUILD" = "true" ] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Building Docker image: $IMAGE"
  docker build \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg INSTALL_TORCH="$INSTALL_TORCH" \
    -t "$IMAGE" \
    "$SCRIPT_DIR"
fi

mkdir -p \
  "$ISAAC_DOCKER_HOME/cache/kit" \
  "$ISAAC_DOCKER_HOME/cache/ov" \
  "$ISAAC_DOCKER_HOME/cache/pip" \
  "$ISAAC_DOCKER_HOME/cache/glcache" \
  "$ISAAC_DOCKER_HOME/cache/computecache" \
  "$ISAAC_DOCKER_HOME/logs" \
  "$ISAAC_DOCKER_HOME/data" \
  "$ISAAC_DOCKER_HOME/documents"

if command -v xhost >/dev/null 2>&1; then
  xhost +local:docker >/dev/null 2>&1 || true
  xhost +SI:localuser:root >/dev/null 2>&1 || true
fi

X11_ARGS=(-e DISPLAY="$DISPLAY_VALUE" -v /tmp/.X11-unix:/tmp/.X11-unix:rw)
XAUTHORITY_FILE="${XAUTHORITY:-$HOME/.Xauthority}"
if [ -f "$XAUTHORITY_FILE" ]; then
  X11_ARGS+=(-e XAUTHORITY=/tmp/.docker.xauth -v "$XAUTHORITY_FILE:/tmp/.docker.xauth:ro")
fi

if [ "$GPU_IDS" = "all" ]; then
  GPU_ARGS=(--gpus all)
else
  GPU_ARGS=(--gpus "device=$GPU_IDS")
fi

CPU_ARGS=()
if [ -n "$CPU_CORES" ]; then
  CPU_ARGS=(--cpuset-cpus "$CPU_CORES")
fi

docker run --rm -it \
  "${GPU_ARGS[@]}" \
  "${CPU_ARGS[@]}" \
  --name "$CONTAINER_NAME" \
  --network host \
  --ipc host \
  --ulimit memlock=-1 \
  --ulimit stack=67108864 \
  -e ACCEPT_EULA=Y \
  -e PRIVACY_CONSENT=Y \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  "${X11_ARGS[@]}" \
  -v "$SCRIPT_DIR:$WORKDIR_IN_CONTAINER:rw" \
  -v "$ISAAC_DOCKER_HOME/cache/kit:/isaac-sim/kit/cache/Kit:rw" \
  -v "$ISAAC_DOCKER_HOME/cache/ov:/root/.cache/ov:rw" \
  -v "$ISAAC_DOCKER_HOME/cache/pip:/root/.cache/pip:rw" \
  -v "$ISAAC_DOCKER_HOME/cache/glcache:/root/.cache/nvidia/GLCache:rw" \
  -v "$ISAAC_DOCKER_HOME/cache/computecache:/root/.nv/ComputeCache:rw" \
  -v "$ISAAC_DOCKER_HOME/logs:/root/.nvidia-omniverse/logs:rw" \
  -v "$ISAAC_DOCKER_HOME/data:/root/.local/share/ov/data:rw" \
  -v "$ISAAC_DOCKER_HOME/documents:/root/Documents:rw" \
  -w "$WORKDIR_IN_CONTAINER" \
  --entrypoint bash \
  "$IMAGE"
