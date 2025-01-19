#!/bin/bash

# Stop on first error
set -e

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

soup run ../soup/code/generate-test/ -args $ROOT_DIR/code/RunTests.wren $ROOT_DIR/out/Wren/Local/Cpp/0.13.2/J_HqSstV55vlb-x6RWC_hLRFRDU/script/Bundles.sml