#!/bin/bash

# Install hakrawler
echo "Installing hakrawler..."
echo 'export PATH="~/go/bin/:$PATH"' >> ~/.bashrc
go install github.com/hakluke/hakrawler@latest
echo ""

# Install lolcat
echo "Installing lolcat..."
sudo apt-get install -y lolcat
echo ""

# Install getips
echo "Installing getips..."
pip3 install getips
sudo apt -y update
echo ""

echo "All installations completed successfully."
