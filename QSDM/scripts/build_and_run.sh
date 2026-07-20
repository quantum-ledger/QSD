#!/bin/bash

# Build the QSD project
echo "Building QSD project..."
go build -o QSD cmd/QSD/main.go
if [ $? -ne 0 ]; then
  echo "Build failed."
  exit 1
fi
echo "Build succeeded."

# Run the QSD node
echo "Starting QSD node..."
./QSD

# Note: Ensure environment variables are set as needed, e.g. USE_SCYLLA=true for ScyllaDB usage
