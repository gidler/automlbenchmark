#!/usr/bin/env bash

HERE=$(dirname "$0")
VERSION=${1:-"stable"}
REPO=${2:-"https://github.com/awslabs/autogluon.git"}
PKG=${3:-"autogluon"}
if [[ "$VERSION" == "latest" ]]; then
    VERSION="master"
fi

# creating local venv
. ${HERE}/../shared/setup.sh ${HERE} true

# Below fixes seg fault on MacOS due to bug in libomp: https://github.com/awslabs/autogluon/issues/1442
if [[ -x "$(command -v brew)" ]]; then
    brew uninstall -f libomp
    wget https://raw.githubusercontent.com/Homebrew/homebrew-core/fb8323f2b170bd4ae97e1bac9bf3e2983af3fdb0/Formula/libomp.rb -P "${HERE}/lib"
    brew install "${HERE}/lib/libomp.rb"
    rm "${HERE}/lib/libomp.rb"
fi

PIP install --upgrade pip -q
PIP install --upgrade setuptools wheel -q

if [[ "$VERSION" == "stable" ]]; then
    PIP install --no-cache-dir -U "${PKG}" -q
    PIP install --no-cache-dir -U "${PKG}.tabular[skex]" -q
elif [[ "$VERSION" =~ ^[0-9] ]]; then
    PIP install --no-cache-dir -U "${PKG}==${VERSION}" -q
    PIP install --no-cache-dir -U "${PKG}.tabular[skex]==${VERSION}" -q
else
    TARGET_DIR="${HERE}/lib/${PKG}"
    rm -Rf ${TARGET_DIR}
    git clone --depth 1 --single-branch --branch ${VERSION} --recurse-submodules ${REPO} ${TARGET_DIR}
    cd ${TARGET_DIR}
    PY_EXEC_NO_ARGS="$(cut -d' ' -f1 <<<"$py_exec")"
    PY_EXEC_DIR=$(dirname "$PY_EXEC_NO_ARGS")
    env PATH="$PY_EXEC_DIR:$PATH" bash -c ./full_install.sh
    PIP install -e tabular/[skex] -q
fi

if [[ ${MODULE} == "timeseries" ]]; then
    PY -c "from autogluon.timeseries.version import __version__; print(__version__)" >> "${HERE}/.setup/installed"
    # TODO: GPU version install
    PIP install "mxnet<2.0" -q
else
    PY -c "from autogluon.tabular.version import __version__; print(__version__)" >> "${HERE}/.setup/installed"
fi
