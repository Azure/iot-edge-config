#!/usr/bin/env bash

source utils.sh
ensure_sudo

log_info "Running install-container-management.sh"

prepare_apt
apt install moby-engine -y
