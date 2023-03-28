#!/bin/bash

# Install hakrawler
echo "Installing hakrawler..."
echo 'export PATH="~/go/bin/:$PATH"' >> ~/.bashrc
go install github.com/hakluke/hakrawler@latest
echo ""

# Install lynx & sqlmap
echo "Installing lynx and sqlmap..."
sudo apt-get install -y lynx sqlmap
echo ""

# Install getips
echo "Installing getips..."
pip3 install getips
sudo apt -y update
echo ""

echo "All installations completed successfully."
