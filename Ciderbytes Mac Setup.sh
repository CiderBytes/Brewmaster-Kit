#!/usr/bin/env bash
# Setup script for new Mac


echo "Starting setup process…"

#Update built-in apps
softwareupdate -ia -verbose

echo "Creating an SSH key for you..."
ssh-keygen -t rsa

echo "Please add this public key to Github \n"
echo "https://github.com/account/ssh \n"
read -p "Press [Enter] key after this..."

#Intall xcode CLI
sudo xcode-select --install

#Accept the Xcode license
sudo xcodebuild -license accept


# Check for Homebrew to be present, install if it's missing
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Update homebrew recipes
echo "Updating Homebrew"
brew update

brew install mas

#read -p 'AppleID: ' uservar
#read -sp 'Password: ' passvar 
#mas signin $uservar $passvar

curl --output ~/Brewfile https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/brewfile
echo "Brewfile downloaded"

echo "Installing from Brewfile"
brew bundle install --file=~/Brewfile

#Configures Homebrew completeion in zsh
curl https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.zshrc > ~/.zshrc
echo "Configuring Homebrew completeion in zsh"
printf "if type brew &>/dev/null; then\n
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH\n

  autoload -Uz compinit\n
  compinit\n
fi" >> ~/.zshrc


echo "Adding /usr/local/sbin to PATH"
echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.zshrc

echo "Cleaning up brew"
brew cleanup

echo "Running Brew Doctor"
brew doctor

#Install Zsh & Oh My Zsh
echo "Installing Oh My ZSH..."
curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh

echo "checking for ohmyzsh upgrade"
upgrade_oh_my_zsh

#Setting up with Dracula theme: https://draculatheme.com/zsh
echo "Setting up Oh My Zsh theme..."
curl --output ~/.oh-my-zsh/themes/lib/async.zsh https://raw.githubusercontent.com/dracula/zsh/44e7b24cc9b102ccdbc2fab277dda5b103a5189c/lib/async.zsh
curl --output ~/.oh-my-zsh/themes/dracula.zsh-theme https://raw.githubusercontent.com/dracula/zsh/44e7b24cc9b102ccdbc2fab277dda5b103a5189c/dracula.zsh-theme

echo "Setting up Zsh plugins..."
git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting


echo "Sourcing .zshrc file"
source ~/.zshrc


echo "Github config"
read -p 'Github username: ' githubuser
read -p 'Github user email: ' githubuseremail

git config --global user.name $githubuser
git config --global user.email $githubuseremail




echo "Mac setup complete"


#echo "Copying dotfiles from Github"
#cd ~
#git clone git@github.com:bradp/dotfiles.git .dotfiles
#cd .dotfiles
#sh symdotfiles
