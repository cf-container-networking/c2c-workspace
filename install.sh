#!/bin/bash

set -e
set -u

function confirm() {
  read -r -p "Are you sure? [y/N] " response
  case $response in
    [yY][eE][sS]|[yY])
      return
      ;;

    *)
      echo "Bailing out, you said no"
      exit 187
      ;;
  esac
}

confirm

cd $(dirname $0)

echo "Install homebrew..."
if [ -z "$(which brew)" ]; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Run the Brewfile..."
brew update
brew tap Homebrew/bundle
ln -sf $(pwd)/Brewfile ${HOME}/.Brewfile
brew bundle --global
brew bundle cleanup

echo "Install the plug vim plugin manager..."
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Symlink the vimrc to .config/nvim/init.vim..."
ln -sf $(pwd)/vimrc ${HOME}/.config/nvim/init.vim

echo "Run the vim plugin install..."
nvim -c "PlugInstall" -c "qall" --headless

echo "Update vim plugins..."
nvim -c "PlugUpdate" -c "qall" --headless

echo "Copy snippets..."
mkdir -p ${HOME}/.vim/Ultisnips

echo "Symlink the go.snippets to .vim/Ultisnips..."
ln -sf $(pwd)/go.snippets ${HOME}/.vim/Ultisnips

echo "Install the vim go binaries..."
nvim -c "GoInstallBinaries" -c "qall!" --headless /tmp/foo.go

echo "Add yamllint for neomake..."
pip3 install -q yamllint

echo "Symlink the git-authors file to .git-authors..."
ln -sf $(pwd)/git-authors ${HOME}/.git-authors

echo "Copy the shared.bash file into .bash_profile"
ln -sf $(pwd)/shared.bash ${HOME}/.bash_profile

echo "Copy the gitconfig file into ~/.gitconfig..."
cp -rf $(pwd)/gitconfig ${HOME}/.gitconfig

echo "Copy the inputrc file into ~/.inputrc..."
ln -sf $(pwd)/inputrc ${HOME}/.inputrc

echo "Link global .gitignore"
ln -sf $(pwd)/global-gitignore ${HOME}/.global-gitignore

echo "link global .git-prompt-colors.sh"
ln -sf $(pwd)/git-prompt-colors.sh ${HOME}/.git-prompt-colors.sh

echo "link global .tmux.conf"
ln -sf $(pwd)/tmux.conf ${HOME}/.tmux.conf

echo "Install ruby 2.3.0..."
rbenv install -s 2.3.0
rbenv global 2.3.0
rm -f ~/.ruby-version
eval "$(rbenv init -)"

echo "Symlink the gemrc file to .gemrc..."
ln -sf $(pwd)/gemrc ${HOME}/.gemrc

echo "Install the bundler gem..."
gem install bundler

echo "Install the bosh cli gem..."
gem install bosh_cli
rbenv rehash

echo "Install the go bosh cli gem..."
go get github.com/cloudfoundry/bosh-cli

echo "Cloning colorschemes..."
if [ ! -d ${HOME}/.config/colorschemes ]; then
  git clone https://github.com/chriskempson/base16-shell.git "${HOME}/.config/colorschemes"
fi

echo "Ignoring ssh security for ephemeral environments..."
if [ ! -d ${HOME}/.ssh ]; then
  mkdir ${HOME}/.ssh
  chmod 0700 ${HOME}/.ssh
fi

if [ -f ${HOME}/.ssh/config ]; then
  echo "Looks like ~/.ssh/config already exists, overwriting..."
fi

cp $(pwd)/ssh_config ${HOME}/.ssh/config
chmod 0644 ${HOME}/.ssh/config

echo "Setting up spectacle..."
cp -f "$(pwd)/com.divisiblebyzero.Spectacle.plist" /Users/pivotal/Library/Preferences/

echo "Creating go/src and workspace..."
go_src=${HOME}/go/src
if [ ! -e ${go_src} ]; then
  mkdir -pv ${HOME}/go/src
fi

if [ -L ${go_src} ]; then
  echo "${go_src} exists, but is a symbolic link"
fi

workspace=${HOME}/workspace
mkdir -p $workspace

echo "Install bosh-target..."
GOPATH="${HOME}/go" go get github.com/kkallday/bosh-target

echo "Install cf-target..."
GOPATH="${HOME}/go" go get github.com/dbellotti/cf-target

echo "Install hclfmt..."
GOPATH="${HOME}/go" go get github.com/fatih/hclfmt

echo "Install ginkgo..."
GOPATH="${HOME}/go" go get github.com/onsi/ginkgo/ginkgo

echo "Install gomega..."
GOPATH="${HOME}/go" go get github.com/onsi/gomega

echo "Install counterfeiter..."
GOPATH="${HOME}/go" go get github.com/maxbrunsfeld/counterfeiter

echo "Install bbl..."
GOPATH="${HOME}/go" go get github.com/cloudfoundry/bosh-bootloader/bbl

echo "Install spiff"
if [ -z "$(which spiff)" ]; then
  wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_darwin_amd64.zip
  unzip spiff_darwin_amd64.zip -d /usr/local/bin
  rm spiff_darwin_amd64.zip
fi

echo "Workstation setup complete, to apply new bash profile, open new window or type: reload"
