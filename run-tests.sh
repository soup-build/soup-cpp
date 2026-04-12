#!/bin/bash

# Stop on first error
set -e

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

soup build code/extension/

TARGET_DIR=$(soup target code/extension/ 2>&1)

soup run ../soup/code/generate-test/ -args $ROOT_DIR/code/run-tests.wren $TARGET_DIR/script/bundles.sml