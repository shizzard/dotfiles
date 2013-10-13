#!/bin/bash

echo "Installing oh-my-zsh...";
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh;

echo "Cloning dotfiles...";
git clone https://github.com/shizzard/dotfiles;

echo "Performing the linking...";
echo ".tmux.conf";
if [ -f ".tmux.conf" ]; then rm .tmux.conf; fi
ln -s ~/dotfiles/.tmux.conf .;
echo ".zshrc";
if [ -f ".zshrc" ]; then rm .zshrc; fi
ln -s ~/dotfiles/.zshrc .;
echo "git.plugin.zsh";
rm .oh-my-zsh/plugins/git/git.plugin.zsh && ln -s ~/dotfiles/git.plugin.zsh .oh-my-zsh/plugins/git/.;
echo "shizzard.zsh-theme";
ln -s ~/dotfiles/shizzard.zsh-theme .oh-my-zsh/themes/.;

echo "Finished";
