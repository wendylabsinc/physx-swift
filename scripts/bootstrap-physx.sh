#!/usr/bin/env bash
set -euo pipefail

tag="${PHYSX_SWIFT_PHYSX_TAG:-ovphysx-0.4.13}"
preset="${PHYSX_SWIFT_PHYSX_PRESET:-linux-clang-cpu-only}"
destination="${1:-physx-upstream}"

case "$(uname -s)" in
  Linux)
    ;;
  *)
    echo "bootstrap-physx.sh currently automates the upstream Linux build presets only." >&2
    echo "For Windows, clone NVIDIA-Omniverse/PhysX and run physx/generate_projects.bat with a vc17win64 preset." >&2
    exit 2
    ;;
esac

if [ ! -d "$destination/.git" ]; then
  git clone --branch "$tag" --depth 1 https://github.com/NVIDIA-Omniverse/PhysX.git "$destination"
fi

pushd "$destination/physx" >/dev/null
./generate_projects.sh "$preset"
make -C "compiler/${preset}-release" -j"$(nproc)"
make -C "compiler/${preset}-release" install
popd >/dev/null

echo "PhysX built at $destination"
echo "Set:"
echo "  export PHYSX_SDK_ROOT=$(cd "$destination" && pwd)"
echo "  export PHYSX_LIBRARY_PATH=$(cd "$destination/physx/bin/linux.$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/aarch64')/release" && pwd)"
echo "  export PHYSX_SWIFT_ENABLE_NATIVE=1"
