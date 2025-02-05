#!/bin/bash

unamer() {
  NAME="$(uname)"

  if [ "$(echo "${NAME}" | grep MINGW)" != "" ] || [ "$(echo "${NAME}" | grep MSYS)" != "" ]; then
  echo "Windows"
  else
  echo "${NAME}"
  fi
}

if [ "$(unamer)" = "Darwin" ]; then
  XCODE_DIR="/Applications/Xcode_VERSION.app/Contents/Developer"

  # In GitHub Actions:
  # env:
  #  PROJECT_TYPE: "UEFI"

  case "${PROJECT_TYPE}" in 
    UEFI)
      BUILD_DEVELOPER_DIR="${XCODE_DIR/VERSION/12.2}"
      ANALYZE_DEVELOPER_DIR="${XCODE_DIR/VERSION/12.2}"
      COVERITY_DEVELOPER_DIR="${XCODE_DIR/VERSION/12.2}"
      ;;
    
    KEXT | TOOL)
      BUILD_DEVELOPER_DIR="${XCODE_DIR/VERSION/12.2}"
      ANALYZE_DEVELOPER_DIR="${XCODE_DIR/VERSION/12.2}"
      COVERITY_DEVELOPER_DIR="${XCODE_DIR/VERSION/12.2}"
      ;;
    
    *)
      echo "ERROR: Invalid project type!"
      exit 1
      ;;
  esac

  SELECTED_DEVELOPER_DIR="${JOB_TYPE}_DEVELOPER_DIR"

  export BUILD_DEVELOPER_DIR
  export ANALYZE_DEVELOPER_DIR
  export COVERITY_DEVELOPER_DIR
  export SELECTED_DEVELOPER_DIR

  if [ -z "${!SELECTED_DEVELOPER_DIR}" ]; then
    echo "ERROR: Invalid or missing job type!"
    exit 1
  fi

  echo "DEVELOPER_DIR=${!SELECTED_DEVELOPER_DIR}" >> "$GITHUB_ENV"

  # Since GITHUB_ENV doesn't affect the current step, need to export DEVELOPER_DIR for subsequent commands.
  export DEVELOPER_DIR="${!SELECTED_DEVELOPER_DIR}"

  if [ -n "${ACID32}" ]; then
    export OVERRIDE_PYTHON3="${DEVELOPER_DIR}/usr/bin/python3"
    src=$(curl -Lfs https://raw.githubusercontent.com/acidanthera/ocbuild/master/clang32-bootstrap.sh) && eval "$src" || exit 1
  fi
fi

colored_text() {
  echo -e "\033[0;36m${1}\033[0m"
}

# Print runner details
colored_text "OS version"
if [ "$(unamer)" = "Darwin" ]; then
  sw_vers
elif [ "$(unamer)" = "Windows" ]; then
  wmic os get caption, version
else
  lsb_release -a
fi

colored_text "git version"
git --version

colored_text "bash version"
bash --version

colored_text "curl version"
curl --version

if [ "$(unamer)" = "Darwin" ]; then
  colored_text "clang version"
  clang --version

  if [ -n "${ACID32}" ]; then
    colored_text "clang32 version"
    ./clang32/clang-12 --version
  fi 

  colored_text "Xcode version"
  xcode-select --print-path
else
  colored_text "gcc version"
  gcc --version
fi