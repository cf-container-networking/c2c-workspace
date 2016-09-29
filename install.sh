#!/bin/bash -e

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

if [ -z "$(which git-hooks)" ]; then
  echo "Install git-hooks because it sucks and is not on brew..."
  curl -fLo /tmp/git-hooks https://github.com/git-hooks/git-hooks/releases/download/v1.1.3/git-hooks_darwin_386.tar.gz --create-dirs

  pushd  /tmp > /dev/null
    tar -xzvf git-hooks
    mv ./build/git-hooks_darwin_386 /usr/local/bin/git-hooks
  popd > /dev/null

  rm -f /tmp/git-hooks
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

echo "Install deoplete..."
nvim -c "UpdateRemotePlugins" -c "qall" --headless
pip3 install -q neovim

echo "Install the vim go binaries..."
nvim -c "GoInstallBinaries" -c "qall!" --headless /tmp/foo.go

echo "Add yamllint for neomake..."
pip3 install -q yamllint

echo "Symlink the git-authors file to .git-authors..."
ln -sf $(pwd)/git-authors ${HOME}/.git-authors

echo "Copy the releng.bash file into .bash_profile"
ln -sf $(pwd)/releng.bash ${HOME}/.bash_profile

echo "Copy the gitconfig file into ~/.gitconfig..."
cp -rf $(pwd)/gitconfig ${HOME}/.gitconfig

echo "Copy the inputrc file into ~/.inputrc..."
ln -sf $(pwd)/inputrc ${HOME}/.inputrc

echo "Link global .gitignore"
ln -sf $(pwd)/releng-gitignore ${HOME}/.releng-gitignore

echo "link global .git-prompt-colors.sh"
ln -sf $(pwd)/git-prompt-colors.sh ${HOME}/.git-prompt-colors.sh

echo "link global .tmux.conf"
ln -sf $(pwd)/tmux.conf ${HOME}/.tmux.conf

echo "Install ruby 2.3.0..."
rbenv install -s 2.3.0
rbenv global 2.3.0
eval "$(rbenv init -)"

echo "Symlink the gemrc file to .gemrc..."
ln -sf $(pwd)/gemrc ${HOME}/.gemrc

echo "Install the bundler gem..."
gem install bundler

echo "Install the bosh cli gem..."
gem install bosh_cli
rbenv rehash

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
if [ ! -e ${workspace} ]; then
  ln -sv ${go_src} ${workspace}
fi

if [ ! -L ${workspace} ]; then
  echo "${workspace} exists, but is not a symbolic link"
fi

echo "Install hclfmt..."
GOPATH="${HOME}/go" go get github.com/fatih/hclfmt

echo "Cloning pcf-releng-ci if it doesn't exist"
if [ ! -d "${GOPATH}/src/github.com/pivotal-cf/pcf-releng-ci" ]; then
  git clone git@github.com:pivotal-cf/pcf-releng-ci.git "${GOPATH}/src/github.com/pivotal-cf/pcf-releng-ci"
fi

echo "Cloning p-runtime if it doesn't exist"
if [ ! -d "${GOPATH}/src/github.com/pivotal-cf/p-runtime" ]; then
  git clone git@github.com:pivotal-cf/p-runtime.git "${GOPATH}/src/github.com/pivotal-cf/p-runtime"
fi

echo "Cloning pcf-patches if it doesn't exist"
if [ ! -d "${GOPATH}/src/github.com/pivotal-cf-experimental/pcf-patches" ]; then
  git clone git@github.com:pivotal-cf-experimental/pcf-patches "${GOPATH}/src/github.com/pivotal-cf-experimental/pcf-patches"
fi

echo "Workstation setup complete"
echo "::::::::::::::::::::::README:::::::::::::::::::::::::"
cat $(pwd)/README.md
