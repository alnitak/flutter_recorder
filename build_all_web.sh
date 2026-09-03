#!/bin/bash
set -euo pipefail

cd web
sh ./compile_worker.sh
sh ./compile_init_recorder_module.sh
sh ./compile_wasm.sh
