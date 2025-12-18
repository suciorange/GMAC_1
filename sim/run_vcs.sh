#!/usr/bin/env bash
set -euo pipefail

out_dir="sim/out"
mkdir -p "${out_dir}"

vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca \
    -f sim/flist.f -top tb_mac_top -o sim/simv \
    -l "${out_dir}/vcs.log"

./sim/simv +DUMP=1 +SPEED=1G -l "${out_dir}/run.log"
