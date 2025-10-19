#!/usr/bin/env bash

set -o nounset
set -o pipefail
set -o errexit
#set -o xtrace

executedFile="${BASH_SOURCE[0]}"
scriptDirectory=$(dirname $(realpath "${executedFile}"))
rootDirectory=$(dirname "${scriptDirectory}")

build_dir=/vortex/linux-speedrun
work_dir=${build_dir}/work
mod_install_path=${work_dir}/modules_install
deploy_path=${work_dir}/deploy
boot=${deploy_path}/boot
build_with_clang_args="LLVM=1 LLVM_IAS=1"
make_flags="O=${build_dir} ${build_with_clang_args}"
make_flags="O=${build_dir}"

rm -Rf ${build_dir}
mkdir -p ${build_dir}

echo "INSTALL_MOD_PATH=${mod_install_path} make ${make_flags} menuconfig"
INSTALL_MOD_PATH=${mod_install_path} make ${make_flags} defconfig
time INSTALL_MOD_PATH=${mod_install_path} make ${make_flags} all
