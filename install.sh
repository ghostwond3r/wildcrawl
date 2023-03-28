#!/bin/bash

# Install hakrawler
echo "Installing hakrawler..."
echo 'export PATH="~/go/bin/:$PATH"' >> ~/.bashrc
go install github.com/hakluke/hakrawler@latest
echo ""

# Install lynx, sqlmap, wget
echo "Installing lynx, sqlmap and wget..."
sudo apt-get install -y lynx sqlmap wget
echo ""

# Install getips
echo "Installing getips..."
pip3 install getips
sudo apt -y update
echo ""

echo "All installations completed successfully."
