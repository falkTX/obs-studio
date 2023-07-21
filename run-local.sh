#!/bin/bash

cd $(dirname "${0}")

OBS_DIR="$(pwd)/build-cmake/rundir/RelWithDebInfo"

export LD_LIBRARY_PATH="${OBS_DIR}/lib"
export LIBOBS_DATA_PATH="${OBS_DIR}/share/obs/libobs/"
export OBS_DATA_PATH="${OBS_DIR}/share/obs/obs-studio/"
export OBS_PLUGINS_DATA_PATH="${OBS_DIR}/share/obs/obs-plugins/"
export OBS_PLUGINS_PATH="${OBS_DIR}/lib/obs-plugins/"

cd "${OBS_DIR}/bin"
# exec gdb -ex run --args
exec "./obs" ${@}
