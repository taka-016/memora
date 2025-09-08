#!/bin/bash

# .devcontainer/.envが存在しない場合は作成
[ ! -f .devcontainer/.env ] && touch .devcontainer/.env || true
