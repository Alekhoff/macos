#!/usr/bin/env bash
set -eu

cd "$(dirname $0)"

bold=$(tput bold)
green=$(tput setaf 2)
normal=$(tput sgr0)

title() {
  echo "${bold}==> $1${normal}"
  echo
}

indent() {
  sed 's/^/  /'
}

echo

# If macOS
if [[ "$(uname)" == "Darwin" ]]; then
  title "Setting initial path."
  if [[ "$(arch)" == "arm64" ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  else
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
  fi

  # Install brew
  if test ! $(which brew); then
    title "Installing Homebrew."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo
  fi

  # Get Brew directory
  BREW_PREFIX=$(brew --prefix)

  # Disable Brew Analytics
  title "Disabling Brew analytics."
  brew analytics off

  # Install brew packages
  title "Installing software..."
  brew bundle | indent
  echo

  # Fix permissions for Zsh compaudit
  chmod go-w $BREW_PREFIX/share

  title "Installing Brew software."
  brew bundle | indent
  echo
  echo "Run 'brew doctor' to verify the installation after you reboot."

  # Ensure Brew Zsh is a valid shell option
  if ! cat /etc/shells | grep $BREW_PREFIX/bin/zsh > /dev/null; then
    title "Adding Homebrew Zsh to list of allowed shells."
    sudo sh -c 'echo ${BREW_PREFIX}/bin/zsh >> /etc/shells'
    echo
  fi

  # Ensure Brew Bash is a valid shell option
  if ! cat /etc/shells | grep $BREW_PREFIX/bin/bash > /dev/null; then
    title "Adding Homebrew Bash to list of allowed shells."
    sudo sh -c 'echo ${BREW_PREFIX}/bin/bash >> /etc/shells'
    echo
  fi

# Use Touch ID for sudo
    if ! cat /etc/pam.d/sudo | grep pam_tid > /dev/null; then
        sudo sed -i '' '2i\
    auth       sufficient     pam_tid.so
    ' /etc/pam.d/sudo
    fi

#Conifg Mac OS
 title "Configuring macOS..."
  ./scripts/config-macos
  echo "Defaults configured!" | indent
  echo

fi

# System naming
# https://uberagent.com/blog/choosing-macos-computer-names-wisely/
set_computername() {
title "Setting macOS ComputerName."
read -ep "Enter new ComputerName (short hostname): " short_hostname
sudo scutil --set ComputerName $short_hostname
}
current_hostname="$(scutil --get ComputerName)"
case $current_hostname in
    "")
        set_computername
        ;;
    "MacBook Air")
        set_computername
        ;;
    "MacBook Pro")
        set_computername
        ;;
esac

if ! [[ $(scutil --get HostName) ]]; then
title "Setting macOS HostName."
read -ep "Enter Hostname (FQDN): " dns_domainname
sudo scutil --set HostName $dns_domainname
fi  
# End of system naming section

# Check that we are using zsh
if [[ "$SHELL" != *"zsh"* ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    title "Changing user shell to Zsh."
    chsh -s $BREW_PREFIX/bin/zsh
    echo "Your shell is changed to Zsh. Restart your terminal or tab." | indent
    echo
  else
    echo "You are not using Zsh. After installing, run 'chsh -s /path/to/zsh'." | indent
    echo
  fi
fi

# Install VSCode extensions
if command -v code >/dev/null 2>&1; then
  title "Installing VSCode extensions from CodeExtensions file."
  [[ -f CodeExtensions ]] && ./bin/vsc_ext bundle
  echo
else
  echo "Install VSCode, then run the './bin/vsc_ext bundle' command."
fi

echo "${green}All done!${normal}" | indent