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
    alias gbtl="gobosh_target_lite"
    alias cft="cf_target"
    alias cftl="cf_target local"
    alias bosh="bosh-cli"
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
  local system_domain
  local vars_store
  system_domain="${env}.c2c.cf-app.com"
  vars_store="vars-store.yml"
  if [ "$env" = "local" ] || [ "$env" = "lite" ]; then
    system_domain="bosh-lite.com"
    vars_store="deployment-vars.yml"
  fi
  envdir=~/workspace/container-networking-deployments/environments/$env
  pushd $envdir 1>/dev/null
    cf api api."${system_domain}" --skip-ssl-validation
    pw=$(grep scim "${vars_store}" | cut -d ' ' -f2)
    cf auth admin "${pw}"
  popd 1>/dev/null
}

gobosh_target ()
{
  gobosh_untarget
  if [ $# = 0 ]; then
    return
  fi
  env=$1
  if [ "$env" = "local" ] || [ "$env" = "lite" ]; then
    gobosh_target_lite
    return
  fi
  pcf=$2
  if [ "$pcf" = "pcf" ]; then
    export BOSH_DIR=~/workspace/container-networking-pcf-deployments/environments/$env
  else
    export BOSH_DIR=~/workspace/container-networking-deployments/environments/$env
  fi

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

gobosh_untarget ()
{
  unset BOSH_DIR
  unset BOSH_USER
  unset BOSH_PASSWORD
  unset BOSH_ENVIRONMENT
  unset BOSH_GW_HOST
  unset BOSH_GW_PRIVATE_KEY
  unset BOSH_CA_CERT
  unset BOSH_DEPLOYMENT
  unset BOSH_CLIENT
  unset BOSH_CLIENT_SECRET
}

gobosh_target_lite ()
{
  gobosh_untarget
  export BOSH_DIR=~/workspace/container-networking-deployments/environments/local

  pushd $BOSH_DIR >/dev/null
    export BOSH_CLIENT="admin"
    export BOSH_CLIENT_SECRET="$(bosh int ./creds.yml --path /admin_password)"
    export BOSH_ENVIRONMENT="vbox"
    export BOSH_CA_CERT=/tmp/bosh-lite-ca-cert
    bosh int ./creds.yml --path /director_ssl/ca > $BOSH_CA_CERT
  popd 1>/dev/null

  export BOSH_DEPLOYMENT=cf;
  if [ "$env" = "ci" ]; then
    export BOSH_DEPLOYMENT=concourse
  fi
}

gobosh_build_manifest ()
{
  bosh -d cf build-manifest -l=$BOSH_DIR/deployment-env-vars.yml --var-errs ~/workspace/cf-deployment/cf-deployment.yml
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

create_upload ()
{
  bosh create-release --force --timestamp-version && bosh upload-release
}

deploy_bosh_lite_w_flannel ()
{
  bosh deploy --no-redact -n ~/workspace/cf-deployment/cf-deployment.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/cf-networking.yml \
  -o ~/workspace/cf-deployment/operations/bosh-lite.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/postgres.yml \
  -o ~/workspace/container-networking-deployments/environments/local/instance-count-overrides.yml \
  --vars-store ~/workspace/container-networking-deployments/environments/local/deployment-vars.yml \
  -v system_domain=bosh-lite.com
}

deploy_bosh_lite ()
{
  bosh deploy --no-redact -n ~/workspace/cf-deployment/cf-deployment.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/cf-networking.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/silk.yml \
  -o ~/workspace/cf-deployment/operations/bosh-lite.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/postgres.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/silk-postgres.yml \
  -o ~/workspace/container-networking-deployments/environments/local/instance-count-overrides.yml \
  --vars-store ~/workspace/container-networking-deployments/environments/local/deployment-vars.yml \
  -v system_domain=bosh-lite.com
}

gobosh_deploy_w_flannel ()
{
  bosh deploy -n ~/workspace/cf-deployment/cf-deployment.yml \
  -o ~/workspace/cf-deployment/operations/gcp.yml \
  -o ~/workspace/cf-deployment/operations/workarounds/use-3-azs-for-router.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/cf-networking.yml \
  -o $BOSH_DIR/opsfile.yml \
  --vars-store $BOSH_DIR/vars-store.yml \
  -v system_domain=$(echo "${BOSH_DIR}" | cut -f 7 -d '/').c2c.cf-app.com
}

gobosh_deploy ()
{
  bosh deploy -n ~/workspace/cf-deployment/cf-deployment.yml \
  -o ~/workspace/cf-deployment/operations/gcp.yml \
  -o ~/workspace/cf-deployment/operations/workarounds/use-3-azs-for-router.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/cf-networking.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/silk.yml \
  -o $BOSH_DIR/opsfile.yml \
  --vars-store $BOSH_DIR/vars-store.yml \
  -v system_domain=$(echo "${BOSH_DIR}" | cut -f 7 -d '/').c2c.cf-app.com
}

create_bosh_lite ()
{
    bosh create-env ~/workspace/bosh-deployment/bosh.yml \
    --state ~/workspace/container-networking-deployments/environments/local/state.json \
    -o ~/workspace/bosh-deployment/virtualbox/cpi.yml \
    -o ~/workspace/bosh-deployment/virtualbox/outbound-network.yml \
    -o ~/workspace/bosh-deployment/bosh-lite.yml \
    -o ~/workspace/bosh-deployment/bosh-lite-runc.yml \
    -o ~/workspace/bosh-deployment/jumpbox-user.yml \
    --vars-store ~/workspace/container-networking-deployments/environments/local/creds.yml \
    -v director_name="Bosh Lite Director" \
    -v internal_ip=192.168.50.6 \
    -v internal_gw=192.168.50.1 \
    -v internal_cidr=192.168.50.0/24 \
    -v outbound_network_name="NatNetwork"

    bosh -e 192.168.50.6 --ca-cert <(bosh int ~/workspace/container-networking-deployments/environments/local/creds.yml --path /director_ssl/ca) alias-env vbox
    export BOSH_CLIENT="admin"
    export BOSH_CLIENT_SECRET="$(bosh int ~/workspace/container-networking-deployments/environments/local/creds.yml --path /admin_password)"
    export BOSH_ENVIRONMENT="vbox"
    export BOSH_DEPLOYMENT="cf"
    export BOSH_CA_CERT="/tmp/bosh-lite-ca-cert"
    bosh int ~/workspace/container-networking-deployments/environments/local/creds.yml --path /director_ssl/ca > ${BOSH_CA_CERT}

    STEMCELL_VERSION="$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path=/stemcells/0/version)"
    echo "will upload stemcell ${STEMCELL_VERSION}"
    bosh -e vbox upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION}"

    bosh -e vbox -n update-cloud-config ~/workspace/cf-deployment/bosh-lite/cloud-config.yml
}

delete_bosh_lite ()
{
    bosh delete-env ~/workspace/bosh-deployment/bosh.yml \
    --state ~/workspace/container-networking-deployments/environments/local/state.json \
    -o ~/workspace/bosh-deployment/virtualbox/cpi.yml \
    -o ~/workspace/bosh-deployment/virtualbox/outbound-network.yml \
    -o ~/workspace/bosh-deployment/bosh-lite.yml \
    -o ~/workspace/bosh-deployment/bosh-lite-runc.yml \
    -o ~/workspace/bosh-deployment/jumpbox-user.yml \
    --vars-store ~/workspace/container-networking-deployments/environments/local/creds.yml \
    -v director_name="Bosh Lite Director" \
    -v internal_ip=192.168.50.6 \
    -v internal_gw=192.168.50.1 \
    -v internal_cidr=192.168.50.0/24 \
    -v outbound_network_name="NatNetwork"
}

unbork_consul ()
{
  bosh vms | grep consul | cut -d ' ' -f1 > /tmp/consul-vms
  cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo /var/vcap/bosh/bin/monit stop consul_agent"
  cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo rm -rf /var/vcap/store/consul_agent/*"
  cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo /var/vcap/bosh/bin/monit start consul_agent"
}

main
unset -f main
