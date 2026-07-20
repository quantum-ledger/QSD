#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <hive-source-dir> <output-dir>" >&2
  exit 64
fi

source_dir="$(cd "$1" && pwd)"
output_dir="$2"
QSD_source_dir="${QSD_SOURCE_DIR:-$source_dir/../../../QSD/source}"
native_dir="$source_dir/native/linux/x64"
edge_agent="$native_dir/QSD-edge-agent"
edge_control="$native_dir/QSD-edge-control"
gpu_helper="$native_dir/QSD-edge-gpu-helper"
miner="$native_dir/QSDminer-console"
cuda_solver="$native_dir/QSD-miner-cuda-solver"
wallet_host="$native_dir/QSD-hive-wallet-host"

mkdir -p "$output_dir"
mkdir -p "$native_dir"

export CI=1
export CSC_IDENTITY_AUTO_DISCOVERY=false
export PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

cd "$source_dir"

hive_version="$(node -p "require('./release/app/package.json').version")"
edge_agent_version="$(tr -d '[:space:]' < "$source_dir/../../QSD-edge-agent/VERSION")"
miner_git_sha="$(git -C "$QSD_source_dir" rev-parse --short HEAD 2>/dev/null || echo unknown)"
miner_build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
miner_ldflags="-s -w -X github.com/blackbeardONE/QSD/pkg/buildinfo.Version=hive-v${hive_version} -X github.com/blackbeardONE/QSD/pkg/buildinfo.GitSHA=${miner_git_sha} -X github.com/blackbeardONE/QSD/pkg/buildinfo.BuildDate=${miner_build_date}"

if [[ -n "${QSD_PREBUILT_CLI:-}" ]]; then
  if [[ ! -f "$QSD_PREBUILT_CLI" ]]; then
    echo "QSD_PREBUILT_CLI does not point to a file." >&2
    exit 66
  fi
  if [[ "$(readlink -f "$QSD_PREBUILT_CLI")" != "$(readlink -f "$native_dir/QSDcli")" ]]; then
    install -m 0755 "$QSD_PREBUILT_CLI" "$native_dir/QSDcli"
  else
    chmod 0755 "$native_dir/QSDcli"
  fi
elif command -v go >/dev/null 2>&1; then
  QSD_source_dir="$(cd "$QSD_source_dir" && pwd)"
  (
    cd "$QSD_source_dir"
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -trimpath \
      -tags dilithium_circl \
      -ldflags="-s -w" \
      -o "$native_dir/QSDcli" \
      ./cmd/QSDcli
  )
  chmod 0755 "$native_dir/QSDcli"
elif [[ -f "$native_dir/QSDcli" ]]; then
  chmod 0755 "$native_dir/QSDcli"
else
  echo "Go is required to build the bundled QSD signer CLI." >&2
  exit 69
fi

if command -v go >/dev/null 2>&1; then
  QSD_source_dir="$(cd "$QSD_source_dir" && pwd)"
  (
    cd "$QSD_source_dir"
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -trimpath \
      -ldflags="-s -w" \
      -o "$wallet_host" \
      ./cmd/QSD-hive-wallet-host
  )
  chmod 0755 "$wallet_host"
elif [[ -f "$wallet_host" ]]; then
  chmod 0755 "$wallet_host"
else
  echo "The Linux QSD Hive wallet native host is missing and Go is unavailable." >&2
  exit 69
fi

if [[ -n "${QSD_PREBUILT_MINER:-}" ]]; then
  if [[ ! -f "$QSD_PREBUILT_MINER" ]]; then
    echo "QSD_PREBUILT_MINER does not point to a file." >&2
    exit 66
  fi
  install -m 0755 "$QSD_PREBUILT_MINER" "$miner"
elif command -v go >/dev/null 2>&1; then
  QSD_source_dir="$(cd "$QSD_source_dir" && pwd)"
  (
    cd "$QSD_source_dir"
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -trimpath \
      -ldflags="$miner_ldflags" \
      -o "$miner" \
      ./cmd/QSDminer-console
  )
  chmod 0755 "$miner"
elif [[ -f "$miner" ]]; then
  chmod 0755 "$miner"
else
  echo "The Linux QSD console miner is missing and Go is unavailable." >&2
  exit 69
fi

if [[ -n "${QSD_PREBUILT_CUDA_SOLVER:-}" ]]; then
  if [[ ! -f "$QSD_PREBUILT_CUDA_SOLVER" ]]; then
    echo "QSD_PREBUILT_CUDA_SOLVER does not point to a file." >&2
    exit 66
  fi
  install -m 0755 "$QSD_PREBUILT_CUDA_SOLVER" "$cuda_solver"
elif command -v nvcc >/dev/null 2>&1; then
  cuda_host_compiler="$(command -v g++-12 || command -v g++)"
  nvcc -O3 -std=c++17 -ccbin "$cuda_host_compiler" \
    -gencode arch=compute_75,code=sm_75 \
    -gencode arch=compute_86,code=sm_86 \
    -gencode arch=compute_89,code=sm_89 \
    -gencode arch=compute_90,code=sm_90 \
    "$QSD_source_dir/cmd/QSD-miner-cuda-solver/main.cu" \
    -o "$cuda_solver"
  chmod 0755 "$cuda_solver"
elif [[ -f "$cuda_solver" ]]; then
  chmod 0755 "$cuda_solver"
else
  echo "The Linux QSD CUDA miner solver is missing and nvcc is unavailable." >&2
  exit 69
fi

if [[ -n "${QSD_PREBUILT_EDGE_AGENT:-}" ]]; then
  if [[ ! -f "$QSD_PREBUILT_EDGE_AGENT" ]]; then
    echo "QSD_PREBUILT_EDGE_AGENT does not point to a file." >&2
    exit 66
  fi
  install -m 0755 "$QSD_PREBUILT_EDGE_AGENT" "$edge_agent"
elif command -v go >/dev/null 2>&1; then
  QSD_source_dir="$(cd "$QSD_source_dir" && pwd)"
  (
    cd "$QSD_source_dir"
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -trimpath \
      -ldflags="-s -w -X main.version=${edge_agent_version}" \
      -o "$edge_agent" \
      ./cmd/QSD-edge-agent
  )
  chmod 0755 "$edge_agent"
elif [[ -f "$edge_agent" ]]; then
  chmod 0755 "$edge_agent"
else
  echo "The Linux QSD edge agent is missing and Go is unavailable." >&2
  exit 69
fi

if [[ -n "${QSD_PREBUILT_EDGE_CONTROL:-}" ]]; then
  if [[ ! -f "$QSD_PREBUILT_EDGE_CONTROL" ]]; then
    echo "QSD_PREBUILT_EDGE_CONTROL does not point to a file." >&2
    exit 66
  fi
  install -m 0755 "$QSD_PREBUILT_EDGE_CONTROL" "$edge_control"
elif command -v go >/dev/null 2>&1; then
  QSD_source_dir="$(cd "$QSD_source_dir" && pwd)"
  (
    cd "$QSD_source_dir"
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -trimpath \
      -ldflags="-s -w -X main.version=${edge_agent_version}" \
      -o "$edge_control" \
      ./cmd/QSD-edge-control
  )
  chmod 0755 "$edge_control"
elif [[ -f "$edge_control" ]]; then
  chmod 0755 "$edge_control"
else
  echo "The Linux QSD Edge Control app is missing and Go is unavailable." >&2
  exit 69
fi

if [[ -n "${QSD_PREBUILT_GPU_HELPER:-}" ]]; then
  if [[ ! -f "$QSD_PREBUILT_GPU_HELPER" ]]; then
    echo "QSD_PREBUILT_GPU_HELPER does not point to a file." >&2
    exit 66
  fi
  install -m 0755 "$QSD_PREBUILT_GPU_HELPER" "$gpu_helper"
elif command -v nvcc >/dev/null 2>&1; then
  cuda_host_compiler="$(command -v g++-12 || command -v g++)"
  nvcc -O3 -std=c++17 -arch=sm_75 -ccbin "$cuda_host_compiler" \
    "$source_dir/../../../QSD/source/cmd/QSD-edge-gpu-helper/main.cu" \
    -o "$gpu_helper"
  chmod 0755 "$gpu_helper"
elif [[ -f "$gpu_helper" ]]; then
  chmod 0755 "$gpu_helper"
else
  echo "The Linux QSD GPU helper is missing and nvcc is unavailable." >&2
  exit 69
fi

# Install the compiler/tooling and runtime dependency trees independently.
# Scripts run only after both trees exist so electron-rebuild can resolve the
# root development dependencies while rebuilding release/app for Linux.
npm ci --ignore-scripts
npm --prefix release/app ci --ignore-scripts
npm exec electron-builder -- install-app-deps
npm run build
npm exec electron-builder -- \
  --linux AppImage \
  --x64 \
  --publish never \
  "--config.directories.output=$output_dir"

test -x "$output_dir/linux-unpacked/resources/native/QSDcli"
test -x "$output_dir/linux-unpacked/resources/native/QSD-hive-wallet-host"
test -x "$output_dir/linux-unpacked/resources/edge/QSD-edge-agent"
test -x "$output_dir/linux-unpacked/resources/edge/QSD-edge-control"
test -x "$output_dir/linux-unpacked/resources/edge/QSD-edge-gpu-helper"
test -x "$output_dir/linux-unpacked/resources/miner/QSDminer-console"
test -x "$output_dir/linux-unpacked/resources/miner/QSD-miner-cuda-solver"
"$output_dir/linux-unpacked/resources/miner/QSDminer-console" --version

version="$hive_version"
archive="$output_dir/QSD-hive-${version}-linux-x64.tar.gz"
tar -C "$output_dir" \
  --transform "s,^linux-unpacked,QSD-hive-${version}-linux-x64," \
  -czf "$archive" \
  linux-unpacked

appimages=("$output_dir"/QSD-hive-*-linux-*.AppImage)
archives=("$output_dir"/QSD-hive-*-linux-*.tar.gz)

if [[ ! -f "${appimages[0]}" || ! -f "${archives[0]}" ]]; then
  echo "Linux release artifacts were not generated as expected." >&2
  exit 1
fi

(
  cd "$output_dir"
  sha256sum QSD-hive-*-linux-*.AppImage QSD-hive-*-linux-*.tar.gz \
    > SHA256SUMS-linux.txt
)
