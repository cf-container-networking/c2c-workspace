# c2c-workspace
workspace configuration for all things c2c.

# why?
there are a whole host of tools to setup workstations but none are simple,
this is an attempt at simple.

# installation
run the provided `install.sh` and enjoy.

To load iTerm preferences, point to this directory under `iTerm2` >
`Preferences` > `Load preferences from a custom folder or URL`.

# assumptions
- install everything with brew
- ruby version will be `2.3.0`
- neovim is the only vim
- the less in the vim config, the better
- we remote pair with [ngrok+tmux](./REMOTE_PAIRING.md) or Screenhero

# some repositories to clone
- cf-container-networking/toque-scaling
- cf-container-networking/toque-test-helpers
- cloudfoundry/bosh-deployment
- cloudfoundry/cf-deployment
- cloudfoundry/cf-deployment-concourse-tasks
- cloudfoundry/cf-networking-deployments
- cloudfoundry/cf-release
- cloudfoundry/diego-release
- cloudfoundry/capi-release
- cloudfoundry/cf-acceptance-tests
- cloudfoundry/garden-runc-release
- cloudfoundry/cf-networking-ci
- cloudfoundry/cf-networking-release
- cloudfoundry-incubator/routing-release
- cloudfoundry/silk (clone to code.cloudfoundry.org)
- cloudfoundry/cf-networking-helpers
