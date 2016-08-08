#!/usr/bin/env bash

set -ue

test() {
  : do nothing
}

test:version() {
  __caploy_get_version
}
