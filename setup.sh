#!/bin/bash

echo "Setting up wire-ios"
echo ""
cd wire-ios
./setup.sh
cd ..

echo "Setting up wire-ios-sync-engine"
echo ""
cd wire-ios-sync-engine
carthage bootstrap --platform ios --use-xcframeworks
cd ..

echo "Setting up wire-ios-data-model"
echo ""
cd wire-ios-data-model
carthage bootstrap --platform ios --use-xcframeworks
cd ..

echo "Setting up wire-ios-protos"
echo ""
cd wire-ios-protos
carthage bootstrap --platform ios --use-xcframeworks
cd ..

echo "Setting up wire-ios-cryptobox"
echo ""
cd wire-ios-cryptobox
carthage bootstrap --platform ios --use-xcframeworks
cd ..

echo "Setting up wire-ios-transport"
echo ""
cd wire-ios-transport
carthage bootstrap --platform ios --use-xcframeworks
cd ..

echo "Setting up wire-ios-link-preview"
echo ""
cd wire-ios-link-preview
carthage bootstrap --platform ios --use-xcframeworks
cd ..

echo "Setting up wire-ios-testing"
echo ""
cd wire-ios-testing
carthage bootstrap --platform ios --use-xcframeworks
cd ..

echo "Done!"
echo ""