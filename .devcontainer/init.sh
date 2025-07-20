#!/bin/bash

# gpg無効化
git config --global --add safe.directory /workspaces/memora
git config --local commit.gpgsign false
