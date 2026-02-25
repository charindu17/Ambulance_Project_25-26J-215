#!/usr/bin/env bash

set -e

echo "🔍 Checking Mosquitto..."

if ! command -v mosquitto >/dev/null 2>&1; then
  echo "📦 Mosquitto not found. Installing..."
  sudo apt update
  sudo apt install -y mosquitto mosquitto-clients
else
  echo "✅ Mosquitto already installed"
fi

echo "🚀 Starting MQTT broker on port 1883..."
mosquitto -v
