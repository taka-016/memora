#!/bin/bash

set -euo pipefail

mkdir -p /var/run/sshd
/usr/sbin/sshd

code-server /workspaces --bind-addr 0.0.0.0:8080 --auth none
