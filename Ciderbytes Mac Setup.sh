#!/usr/bin/env bash
# Setup script for new Mac
#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/Ciderbytes%20Mac%20Setup.sh)"

echo "Grant sudo access upfront"
sudo -v

echo "Starting setup process…"

echo -e "\033[1;31m Sign into the App Store before proceeding\n\033[0m"
open -a /System/Applications/App\ Store.app
read -p $'\e[1;31mPress [Enter] key after this...\e[0m'

#Update built-in apps
sudo softwareupdate -ia --verbose

read -n1 -p "Generate SSH Key? [y] `echo $'\n> '`" doit 
case $doit in  
  y|Y) 
  echo -e "\n Creating an SSH key for you..."
  read -p 'email address: ' emailaddress
  ssh-keygen -t rsa -C $emailaddress
  eval "$(ssh-agent -s)"
  printf "Host *\n
    AddKeysToAgent yes\n
    UseKeychain yes\n
    IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config
  ssh-add -K ~/.ssh/id_rsa;;
*) 
echo -e "\n Skipping SSH key creation \n";;
esac 

echo -e "Please add public key to Github \n"
echo -e "\033[1;34m https://github.com/account/ssh \n\033[0m"
open "https://github.com/account/ssh"
pbcopy < ~/.ssh/id_rsa.pub
echo -e "\033[1;31m Your SSH key has been copied to your clipboard\033[0m"
read -p $'\e[1;31mPress [Enter] key after this...\e[0m'


echo "Setting gitignore file"
curl https://raw.githubusercontent.com/github/gitignore/master/Global/macOS.gitignore -o ~/.gitignore
git config --global core.excludesfile ~/.gitignore

echo "Configure Git to ensure line endings in files you checkout are correct for OS X"
git config --global core.autocrlf input

##Check for Xcode CLI and install if not present
##Commented out as Homebrew will install when first run
#if test ! $(which xcode-select); then
  #Intall xcode CLI
#  echo "Installing Xcode CLI"
#  sudo xcode-select --install
#fi


# Check for Homebrew to be present, install if it's missing
if test ! $(which brew); then
    echo "Installing homebrew..."
    #ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Update homebrew recipes
echo "Updating Homebrew"
brew update

echo "Upgrading Homebrew installs"
brew upgrade

#Install MAS
echo "Installing MAS"
brew install mas

#Following MAS settings not currently supported
#read -p 'AppleID: ' uservar
#read -sp 'Password: ' passvar 
#mas signin $uservar $passvar

#Check for Xcodebuild install
if test ! $(which xcodebuild); then
  #Install Xcode
  echo "Installing Xcode"
  mas install 497799835
  echo "Xcode Install Complete"
  #Accept the Xcode license
  sudo xcodebuild -license accept
fi


#Copy powerlevel10k config file in place
curl --output ~/.p10k.zsh https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.p10k.zsh
echo "p10k.zsh downloaded"

curl --output ~/Brewfile https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/brewfile
echo "Brewfile downloaded"

echo "Installing from Brewfile"
brew bundle install --file=~/Brewfile

#Copying .zshrc in place
mv ~/.zshrc ~/.zshrc.bak
curl https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.zshrc > ~/.zshrc

echo "Adding /usr/local/sbin to PATH"
export PATH="/usr/local/sbin:$PATH"

echo "Running Brew Doctor"
brew doctor

echo "Cleaning up brew"
brew cleanup


#Install Zsh & Oh My Zsh
echo "Installing Oh My ZSH..."
curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh

#Setting up with Dracula theme: https://draculatheme.com/zsh
#echo "Setting up Oh My Zsh theme..."
#mkdir ~/.oh-my-zsh/themes/lib/
#curl --output ~/.oh-my-zsh/themes/lib/async.zsh https://raw.githubusercontent.com/dracula/zsh/44e7b24cc9b102ccdbc2fab277dda5b103a5189c/lib/async.zsh
#curl --output ~/.oh-my-zsh/themes/dracula.zsh-theme https://raw.githubusercontent.com/dracula/zsh/44e7b24cc9b102ccdbc2fab277dda5b103a5189c/dracula.zsh-theme

echo "Setting up Zsh plugins..."

if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-nvm ];
  then
  git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
  else 
  echo "zsh-nvm already installed"
fi

if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ];
  then 
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  else 
  echo "zsh-autosuggestions already installed"
fi

if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/z-master ];
  then
  git clone https://github.com/rupa/z.git ~/.oh-my-zsh/custom/plugins/z-master
  else 
  echo "z or (aka z-master) already installed"
fi

printf "\n${BLUE}%s${RESET}\n" "Updating custom plugins"
cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/

for plugin in */; do
  if [ -d "$plugin/.git" ]; then
     printf "${YELLOW}%s${RESET}\n" "${plugin%/}"
     git -C "$plugin" pull
  fi
done

#MOVED TO HOMEBREW:
#git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting


#Resolve “zsh compinit: insecure directories” error with Homebrew shell completion
chmod -R go-w "$(brew --prefix)/share"

#echo "Sourcing .zshrc file"
#source ~/.zshrc

##Checking for update using omz won't work in this script as it's a zsh command
#echo "checking for ohmyzsh upgrade"
#omz update

echo "Github config"
read -p 'Github username: ' githubuser
read -p 'Github user email: ' githubuseremail

git config --global user.name $githubuser
git config --global user.email $githubuseremail
git config --global credential.helper osxkeychain

###Set default text editor for Git
##Atom
#git config --global core.editor "atom --wait"
##TextMate
#git config --global core.editor "mate -w"
##Sublime
#git config --global core.editor "subl -n -w"
##VSCode
git config --global core.editor "code --wait"

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

# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

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

#Edit Visual Studio Code terminal font by going to Settings -> terminal.integrated.fontFamily and set to "MesloLGS NF"
#Set iTerm2 font to "MesloLGS NF"

echo -e "Mac setup complete, it is recommeneded try update oh-my-zsh in a new terminal window with the following command and then restarting your computer:\n \033[1;31m omz update \033[1;0m"

#echo "Copying dotfiles from Github"
#cd ~
#git clone git@github.com:bradp/dotfiles.git .dotfiles
#cd .dotfiles
#sh symdotfiles
