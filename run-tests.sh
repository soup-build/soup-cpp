#!/bin/bash

# Stop on first error
set -e

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

soup build ../soup/code/generate-test/
soup run ../soup/code/generate-test/ -args $ROOT_DIR/code/run-tests.wren $ROOT_DIR/out/Wren/Local/Cpp/0.16.1/J_HqSstV55vlb-x6RWC_hLRFRDU/script/bundles.sml