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
    alias gut="git pull -r && tree ."
    alias guv="git pull -r && tree vsphere"
    alias gua="git pull -r && tree aws"
    alias guo="git pull -r && tree openstack"
    alias guc="git pull -r && tree vcloud"
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
    colorscheme="${HOME}/.config/colorschemes/base16-flat.dark.sh"
    [[ -s "${colorscheme}" ]] && source "${colorscheme}"
  }

  function setup_git_hooks() {
    git config --system --add hooks.global /usr/local/share/githooks

    REPOS=(
    "${GOPATH}/src/github.com/pivotal-cf/pcf-releng-ci"
    "${GOPATH}/src/github.com/pivotal-cf/p-runtime"
    "${GOPATH}/src/github.com/pivotal-cf-experimental/pcf-patches"
    )

    for repo in ${REPOS[@]}; do
      if [ -d "${repo}/.git" ]; then
        pushd ${repo} > /dev/null

        for hook in $(ls .git/hooks/* | grep -v .sample); do
          if $(grep -q git-hooks ${hook}); then
            continue # already using git-hooks
          fi

          hook_dir="${repo}/githooks/$(basename ${hook})"
          mkdir -p ${hook_dir}

          cp "${hook}" "${hook_dir}/recovered-hook"
        done

        git hooks install > /dev/null

        popd > /dev/null
      fi
    done
  }

  function setup_git_secrets_hooks() {
    if [ ! -d "/usr/local/share/githooks-templatedir" ]; then
      pushd "${GOPATH}/src/github.com/pivotal-cf-experimental/releng-workspace" > /dev/null
        ./git-hooks-template
      popd > /dev/null
    fi
    git secrets --register-aws --global
    git secrets --add 'MII'

    secrets_hooks=(
      pre_commit
      commit_msg
      prepare_commit_msg
    )

    for secrets_hook in ${secrets_hooks[@]}; do
      local hook_dir_name
      hook_dir_name=$(echo "${secrets_hook}" | sed 's/_/-/g')

      local hook_path
      hook_path="/usr/local/share/githooks/${hook_dir_name}/00-git-secrets"
      mkdir -p $(dirname ${hook_path})

      cat <<EOF > ${hook_path}
#!/usr/bin/env bash
git secrets --${secrets_hook}_hook -- "$@"
EOF
      chmod 755 ${hook_path}
    done
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
    git_hooks
    git_secrets_hooks
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
  workspace="${GOPATH}/src/github.com/pivotal-cf-experimental/releng-workspace"

  if [[ ! -d "${workspace}" ]]; then
    git clone git@github.com:pivotal-cf-experimental/releng-workspace "${workspace}"
  fi

  pushd "${workspace}" > /dev/null
    git diff --exit-code > /dev/null
    if [[ "$?" = "0" ]]; then
      git pull -r
      bash -c "./install.sh"
    else
      echo "Cannot reinstall. There are unstaged changes in the releng-workspace repo."
      git diff
    fi
  popd > /dev/null
}

function concourse_credentials() {
  if [[ "${1}" = "edit" ]]; then
      lpass edit --sync=now --notes 13068316046804935
      lpass edit --sync=now --notes 3061742207521107901
  else
    cat \
      <(lpass show --sync=now --notes 13068316046804935) \
      <(lpass show --sync=now --notes 3061742207521107901)
  fi
}

function azure_credentials() {
  local cmd
  cmd="${1-show}"

  lpass ${cmd} --sync=now --notes 7819668678774416323
}

function gcp_credentials() {
  local cmd
  cmd="${1-show}"

  lpass ${cmd} --sync=now --notes 1211441631940037867
}

function aws_credentials() {
  local cmd
  cmd="${1-show}"

  lpass ${cmd} --sync=now --notes 24431544792306889
}

main
unset -f main
