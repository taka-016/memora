#!/bin/bash

echo "flutter build started"
stdbuf -oL -eL flutter build apk --debug --verbose || echo "flutter build failed with exit code $?"
echo "flutter build completed"
