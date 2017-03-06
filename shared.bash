#!/usr/bin/env bash

function main() {
  function setup_aliases() {
    alias vim=nvim
    alias vi=nvim
    alias ll="ls -al"
    alias be="bundle exec"
    alias bake="bundle exec rake"
    alias drm='docker rm $(docker ps -a -q)'
    alias drmi='docker rmi $(docker images -q)'

    #git aliases
    alias gst="git status"
    alias gd="git diff"
    alias gap="git add -p"
    alias gup="git pull -r"
    alias gp="git push"
    alias ga="git add"

    alias gbt="gobosh_target"
    alias cft="cf_target"
  }

  function setup_environment() {
    export CLICOLOR=1
    export LSCOLORS exfxcxdxbxegedabagacad

    # go environment
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin

    # git duet config
    export GIT_DUET_GLOBAL=true
    export GIT_DUET_ROTATE_AUTHOR=1

    # setup path
    export PATH=$GOBIN:$PATH

    export EDITOR=nvim
  }

  function setup_rbenv() {
    eval "$(rbenv init -)"
  }

  function setup_aws() {
    # set awscli auto-completion
    complete -C aws_completer aws
  }

  function setup_fasd() {
    local fasd_cache
    fasd_cache="$HOME/.fasd-init-bash"

    if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
      fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install >| "$fasd_cache"
    fi

    source "$fasd_cache"
    eval "$(fasd --init auto)"
  }

  function setup_completions() {
    if [ -d $(brew --prefix)/etc/bash_completion.d ]; then
      for F in $(brew --prefix)/etc/bash_completion.d/*; do
        . ${F}
      done
    fi
  }

  function setup_direnv() {
    eval "$(direnv hook bash)"
  }

  function setup_gitprompt() {
    if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
      # git prompt config
      export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal
      export GIT_PROMPT_ONLY_IN_REPO=0
      export GIT_PROMPT_THEME="Custom"

      source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
    fi
  }

  function setup_colors() {
    local colorscheme
    colorscheme="${HOME}/.config/colorschemes/scripts/base16-monokai.sh"
    [[ -s "${colorscheme}" ]] && source "${colorscheme}"
  }



  local dependencies
    dependencies=(
        aliases
        environment
        colors
        rbenv
        aws
        fasd
        completions
        direnv
        gitprompt
      )

  for dependency in ${dependencies[@]}; do
    eval "setup_${dependency}"
    unset -f "setup_${dependency}"
  done
}

function reload() {
  source "${HOME}/.bash_profile"
}

function reinstall() {
  local workspace
  workspace="~/workspace/c2c-workspace"

  if [[ ! -d "${workspace}" ]]; then
    git clone https://github.com/cloudfoundry-incubator/c2c-workspace "${workspace}"
  fi

  pushd "${workspace}" > /dev/null
    git diff --exit-code > /dev/null
    if [[ "$?" = "0" ]]; then
      git pull -r
      bash -c "./install.sh"
    else
      echo "Cannot reinstall. There are unstaged changes in the c2c-workspace repo."
      git diff
    fi
  popd > /dev/null
}

function cf_bosh_lite {
    if (( $# == 0 ))
			then echo usage: cf_bosh_lite password;
    else
    	cf api api.bosh-lite.com --skip-ssl-validation && cf auth admin $1 && cf t -o o -s s
    fi
}

function cf_create_org {
		cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s
}

function bosh_ssh_c2c {
  if (( $# != 1 ))
    then echo "Usage: bosh_ssh_c2c <env>"
  else
    bosh target bosh.$1.c2c.cf-app.com
    bosh download manifest $1-diego /tmp/$1-diego.yml
    bosh -d /tmp/$1-diego.yml ssh --gateway_host bosh.$1.c2c.cf-app.com --gateway_user vcap --gateway_identity_file ~/workspace/container-networking-deployments/environments/$1/keypair/id_rsa_bosh
  fi
}

cf_target ()
{
  if (( $# != 1 )); then
    echo "missing environment-name"
    echo ""
    echo "example usage:"
    echo "cft environment-name"
    return
  fi
  env=$1
  envdir=~/workspace/container-networking-deployments/environments/$env
  pushd $envdir 1>/dev/null
    cf api api."${env}".c2c.cf-app.com --skip-ssl-validation
    pw=$(grep scim vars-store.yml | cut -d ' ' -f2)
    cf auth admin "${pw}"
  popd 1>/dev/null
}

gobosh_target ()
{
  if (( $# != 1 )); then
    unset BOSH_DIR
    unset BOSH_USER
    unset BOSH_PASSWORD
    unset BOSH_ENVIRONMENT
    unset BOSH_GW_HOST
    unset BOSH_GW_PRIVATE_KEY
    unset BOSH_CA_CERT
    unset BOSH_DEVELOPMENT
    unset BOSH_CLIENT
    unset BOSH_CLIENT_SECRET
    return
  fi
  env=$1
  export BOSH_DIR=~/workspace/container-networking-deployments/environments/$env

  pushd $BOSH_DIR 1>/dev/null
    export BOSH_CLIENT=$(bbl director-username)
    export BOSH_CLIENT_SECRET=$(bbl director-password)
    export BOSH_ENVIRONMENT=$(bbl director-address)
    # TODO: remove me after bbl'ing up with bbl 1.2+
    export BOSH_GW_HOST=$(bbl director-address | cut -d '/' -f 3 | cut -d ':' -f1)
    export BOSH_GW_PRIVATE_KEY=/tmp/$env-ssh-key
    bbl ssh-key > $BOSH_GW_PRIVATE_KEY
    chmod 600 $BOSH_GW_PRIVATE_KEY
    export BOSH_CA_CERT=/tmp/$env-ca-cert
    bbl director-ca-cert > $BOSH_CA_CERT
    chmod 600 $BOSH_CA_CERT
  popd 1>/dev/null

  export BOSH_DEPLOYMENT=cf;
  if [ "$env" = "ci" ]; then
    export BOSH_DEPLOYMENT=concourse
  fi
}

gobosh_build_manifest ()
{
  bosh-cli -d cf build-manifest -l=$BOSH_DIR/deployment-env-vars.yml --var-errs ~/workspace/cf-deployment/cf-deployment.yml
}

gobosh_patch_manifest ()
{
  pushd ~/workspace/cf-deployment 1>/dev/null
    git apply ../container-networking-ci/netman-cf-deployment.patch
  popd 1>/dev/null
}

extract_manifest ()
{
  bosh task $1 --debug | deployment-extractor
}

unbork_consul ()
{
  bosh-cli vms | grep consul | cut -d ' ' -f1 > /tmp/consul-vms
  cat /tmp/consul-vms | xargs -n1 bosh-cli ssh -c "sudo /var/vcap/bosh/bin/monit stop consul_agent"
  cat /tmp/consul-vms | xargs -n1 bosh-cli ssh -c "sudo rm -rf /var/vcap/store/consul_agent/*"
  cat /tmp/consul-vms | xargs -n1 bosh-cli ssh -c "sudo /var/vcap/bosh/bin/monit start consul_agent"
}

main
unset -f main
