#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./build.sh [options] [-- docker build args...]

Builds the current directory as a local devastation image, pushes it to the
local registry, and restarts the matching Kubernetes deployment if it exists.

Defaults are scanned from ../cluster-ops/terraform/*.tf when available.

Options:
  --no-push           Build the image but do not push it.
  --no-restart        Do not check or restart Kubernetes.
  --namespace NAME    Override the Kubernetes namespace.
  --deployment NAME   Override the Kubernetes deployment name.
  --image IMAGE       Override the full image tag.
  -h, --help          Show this help.

Environment:
  DEVASTATION_DOCKER_REGISTRY  default: registry.deva.station
  DEVASTATION_IMAGE_OWNER      default: current OS user
  APT_PROXY                   default: http://127.0.0.1:3142
  GEM_MIRROR                  default: GEM_SOURCE or http://127.0.0.1:9292
  DEVASTATION_NOTIFY          set to 0 to disable progress notifications
USAGE
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

notify_devastation() {
  local urgency="$1"
  local title="$2"
  local body="${3:-}"

  if [[ "${DEVASTATION_NOTIFY:-1}" != "1" ]]; then
    return 0
  fi

  if [[ -x /usr/local/bin/devastation-notify ]]; then
    /usr/local/bin/devastation-notify "$urgency" "$title" "$body" || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="devastation" --urgency="$urgency" "$title" "$body" >/dev/null 2>&1 || true
  else
    printf '[%s] %s' "$urgency" "$title"
    if [[ -n "$body" ]]; then
      printf ': %s' "$body"
    fi
    printf '\n'
  fi
}

scan_cluster_ops() {
  local project="$1"
  local cluster_ops_dir="${CLUSTER_OPS_DIR:-../cluster-ops}"
  local tf_file

  [[ -d "${cluster_ops_dir}/terraform" ]] || return 0

  for tf_file in "${cluster_ops_dir}"/terraform/*.tf; do
    [[ -f "$tf_file" ]] || continue

    local scanned_name scanned_namespace scanned_image
    scanned_name="$(sed -n 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$tf_file" | head -n 1)"
    [[ "$scanned_name" == "$project" ]] || continue

    scanned_namespace="$(sed -n 's/^[[:space:]]*namespace[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$tf_file" | head -n 1)"
    scanned_image="$(sed -n 's/^[[:space:]]*image[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$tf_file" | head -n 1)"

    if [[ -n "$scanned_namespace" ]]; then
      namespace="$scanned_namespace"
    fi
    if [[ -n "$scanned_name" ]]; then
      deployment="$scanned_name"
    fi
    if [[ -n "$scanned_image" ]]; then
      image="$scanned_image"
    fi

    cluster_source="$tf_file"
    return 0
  done
}

push_image=1
restart_kubernetes=1
docker_build_args=()

project="$(basename "$PWD")"
registry="${DEVASTATION_DOCKER_REGISTRY:-registry.deva.station}"
owner="${DEVASTATION_IMAGE_OWNER:-${USER:-$(id -un)}}"
image="${registry}/${owner}/${project}"
namespace="$project"
deployment="$project"
cluster_source=""

scan_cluster_ops "$project"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push)
      push_image=0
      shift
      ;;
    --no-restart)
      restart_kubernetes=0
      shift
      ;;
    --namespace)
      namespace="${2:-}"
      if [[ -z "$namespace" ]]; then
        echo "--namespace requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --deployment)
      deployment="${2:-}"
      if [[ -z "$deployment" ]]; then
        echo "--deployment requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --image)
      image="${2:-}"
      if [[ -z "$image" ]]; then
        echo "--image requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      docker_build_args+=("$@")
      break
      ;;
    *)
      docker_build_args+=("$1")
      shift
      ;;
  esac
done

require_command docker

if [[ ! -f Dockerfile ]]; then
  echo "No Dockerfile found in $PWD" >&2
  exit 1
fi

on_exit() {
  local rc=$?
  if [[ "$rc" != "0" ]]; then
    notify_devastation critical "Build failed" "${project} exited with status ${rc}."
  fi
}
trap on_exit EXIT

apt_proxy="${APT_PROXY:-http://127.0.0.1:3142}"
gem_mirror="${GEM_MIRROR:-${GEM_SOURCE:-http://127.0.0.1:9292}}"

echo "Project:    ${project}"
echo "Image:      ${image}"
echo "Namespace:  ${namespace}"
echo "Deployment: ${deployment}"
if [[ -n "$cluster_source" ]]; then
  echo "Cluster:    ${cluster_source}"
fi

notify_devastation normal "Build started" "${project}: building ${image}."

docker_build_command=(
  docker build
  --network=host
  --build-arg "APT_PROXY=${apt_proxy}"
  --build-arg "GEM_MIRROR=${gem_mirror}"
  -t "$image"
)

docker_build_command+=("${docker_build_args[@]}")
docker_build_command+=(.)

echo "Building ${image}..."
"${docker_build_command[@]}"
notify_devastation low "Build image complete" "${project}: built ${image}."

if [[ "$push_image" == "1" ]]; then
  notify_devastation normal "Push started" "${project}: pushing ${image}."
  echo "Pushing ${image}..."
  docker push "$image"
  notify_devastation low "Push complete" "${project}: pushed ${image}."
else
  notify_devastation low "Push skipped" "${project}: built ${image} locally."
fi

if [[ "$restart_kubernetes" != "1" ]]; then
  notify_devastation low "Kubernetes restart skipped" "${project}: --no-restart was used."
  trap - EXIT
  notify_devastation low "Build complete" "${project}: ${image}."
  exit 0
fi

if ! command -v kubectl >/dev/null 2>&1; then
  notify_devastation low "Kubernetes restart skipped" "${project}: kubectl is not installed."
  trap - EXIT
  notify_devastation low "Build complete" "${project}: ${image}."
  exit 0
fi

notify_devastation normal "Checking Kubernetes" "${project}: looking for ${namespace}/${deployment}."

if ! kubectl -n "$namespace" get "deployment/${deployment}" >/dev/null 2>&1; then
  notify_devastation low "Kubernetes restart skipped" "${project}: ${namespace}/${deployment} is not deployed."
  trap - EXIT
  notify_devastation low "Build complete" "${project}: ${image}."
  exit 0
fi

notify_devastation normal "Restarting Kubernetes" "${project}: restarting ${namespace}/${deployment}."
echo "Restarting ${namespace}/${deployment}..."
kubectl -n "$namespace" rollout restart "deployment/${deployment}"

notify_devastation normal "Waiting for rollout" "${project}: waiting for ${namespace}/${deployment}."
echo "Waiting for rollout..."
kubectl -n "$namespace" rollout status "deployment/${deployment}" --timeout=300s

notify_devastation normal "Preparing database" "${project}: applying pending migrations."
echo "Preparing database..."
kubectl -n "$namespace" exec "deployment/${deployment}" -- bin/rails db:prepare

trap - EXIT
notify_devastation low "Build complete" "${project}: deployed ${image}."
echo "Build complete: ${image}"
