#!/usr/bin/env bash
# Setup script for new Mac


echo "Starting setup process…"

#Update built-in apps
sudo softwareupdate -ia

echo "Creating an SSH key for you..."
read -p 'email address: ' emailaddress
ssh-keygen -t rsa -C $emailaddress
eval "$(ssh-agent -s)"
printf "Host *\n
  AddKeysToAgent yes\n
  UseKeychain yes\n
  IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config
ssh-add -K ~/.ssh/id_rsa


echo -e "Please add this public key to Github \n"
echo -e "https://github.com/account/ssh \n"
read -p "Press [Enter] key after this..."

pbcopy < ~/.ssh/id_rsa.pub
echo "Your SSH key has been copied to your clipboard"

echo "Setting gitignore file"
curl https://raw.githubusercontent.com/github/gitignore/master/Global/macOS.gitignore -o ~/.gitignore
git config --global core.excludesfile ~/.gitignore


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

#Copying .zshrc in place
curl https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.zshrc > ~/.zshrc

echo "Adding /usr/local/sbin to PATH"
echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.zshrc

echo "Cleaning up brew"
brew cleanup

echo "Running Brew Doctor"
brew doctor

#Install Zsh & Oh My Zsh
echo "Installing Oh My ZSH..."
curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh

#Setting up with Dracula theme: https://draculatheme.com/zsh
echo "Setting up Oh My Zsh theme..."
mkdir ~/.oh-my-zsh/themes/lib/
curl --output ~/.oh-my-zsh/themes/lib/async.zsh https://raw.githubusercontent.com/dracula/zsh/44e7b24cc9b102ccdbc2fab277dda5b103a5189c/lib/async.zsh
curl --output ~/.oh-my-zsh/themes/dracula.zsh-theme https://raw.githubusercontent.com/dracula/zsh/44e7b24cc9b102ccdbc2fab277dda5b103a5189c/dracula.zsh-theme

echo "Setting up Zsh plugins..."
git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting


echo "Sourcing .zshrc file"
source ~/.zshrc

echo "checking for ohmyzsh upgrade"
omz update

echo "Github config"
read -p 'Github username: ' githubuser
read -p 'Github user email: ' githubuseremail

git config --global user.name $githubuser
git config --global user.email $githubuseremail
git config --global credential.helper osxkeychain


echo "Configuring Mac Preferences"

#Allow text in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool TRUE

#"Use column view in all Finder windows by default"
defaults write com.apple.finder FXPreferredViewStyle Clmv

#"Setting Dock to auto-hide and removing the auto-hiding delay"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

#"Disable the sudden motion sensor as its not useful for SSDs"
sudo pmset -a sms 0

#"Disable annoying backswipe in Chrome"
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

#"Setting screenshot format to PNG"
defaults write com.apple.screencapture type -string "png"

#"Enabling Safari's debug menu"
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

#"Allow hitting the Backspace key to go to the previous page in history"
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

#"Enabling the Develop menu and the Web Inspector in Safari"
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true

#"Adding a context menu item for showing the Web Inspector in web views"
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

#Set Sublime Text to open as editor from CLI
ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl

#Send Screenshots to Screenshots folder on Desktop
mkdir -p ~/Desktop/Screenshots
defaults write com.apple.screencapture location ~/Desktop/Screenshots && killall SystemUIServer

#"Setting screenshots location to ~/Desktop"
#defaults write com.apple.screencapture location -string "$HOME/Desktop"


#"Disabling OS X Gate Keeper"
#"(You'll be able to install any app you want from here on, not just Mac App Store apps)"
#sudo spctl --master-disable
#sudo defaults write /var/db/SystemPolicy-prefs.plist enabled -string no
#defaults write com.apple.LaunchServices LSQuarantine -bool false

#"Saving to disk (not to iCloud) by default"
#defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

#"Disable smart quotes and smart dashes as they are annoying when typing code"
#defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
#defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

#"Showing all filename extensions in Finder by default"
#defaults write NSGlobalDomain AppleShowAllExtensions -bool true

#"Disabling the warning when changing a file extension"
#defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

killall Finder

#Add VSCode to Path
cat << EOF >> ~/.zshrc
# Add Visual Studio Code (code)
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
EOF


echo "Mac setup complete, it is recommeneded to restart your computer"


#echo "Copying dotfiles from Github"
#cd ~
#git clone git@github.com:bradp/dotfiles.git .dotfiles
#cd .dotfiles
#sh symdotfiles
