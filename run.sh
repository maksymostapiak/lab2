#!/bin/bash

echo "=== Building Single-stage Image ==="
docker build -f Dockerfile.single -t lab_single_stage .

echo -e "\n=== Building Multi-stage Image ==="
docker build -f Dockerfile.multi -t lab_multi_stage .

echo -e "\n=== Running Multi-stage Container ==="
docker run --rm -e APP_ENV=testing lab_multi_stage