#!bin/bash

# Install dotfiles
cd ~
rm -f .zshrc .aliases
wget https://raw.githubusercontent.com/georgehwho/dotfiles/main/zsh/.zshrc
wget https://raw.githubusercontent.com/georgehwho/dotfiles/main/zsh/.aliases
source .zshrc .aliases

exit 0