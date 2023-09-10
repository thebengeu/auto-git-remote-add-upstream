# Automatic `git remote add upstream`

Git alias and hook to automatically add `upstream` remote using auto-detected URL when cloning your public or private forks.

## Requirements

- [jq](https://jqlang.github.io/jq/download/)

## Setup `rau` Git Alias and Hook

```console
curl -s https://raw.githubusercontent.com/thebengeu/auto-git-remote-add-upstream/master/setup-git-alias-and-hook.sh | sh
```

## `rau` Git Alias

If the `upstream` remote is not set and there are commits where you aren't the author and the `origin` remote URL seems to be a GitHub repo under your username, `git rau` will attempt to add the `upstream` remote using the auto-detected URL of:

1. The upstream repo that `origin` was forked from, if explicitly set on GitHub.
2. The earliest-created repo on GitHub that contains the latest local commit not authored by you.
   - This heuristic should be good enough for most cases, whether your fork is public or private.
   - If that latest local commit isn't recent, in rare cases another fork containing that commit, that isn't explicitly set as a fork on GitHub, may have overtaken the earliest-created repo in some measures. Any such repos created later but with more stars, forks, open issues or watchers will be listed for your consideration.

## `post-checkout` Git Hook

The setup script adds `git rau` to the `post-checkout` Git hook within the [template directory](https://git-scm.com/docs/git-init#_template_directory) set in the `init.templateDir` Git configuration variable, which will be set to `$XDG_CONFIG_HOME/git/template` if not already set.

## Options

- Run `setup-git-alias-and-hook.sh <alias-name>` to use an alias name other than `rau`.
- Set the `GH_TOKEN` or `GITHUB_TOKEN` environment variables to a GitHub personal access token to:
  - Increase the GitHub API rate limit from 60 to 5000 requests per hour.
  - Handle cases where the upstream repo is private.
- Set the `GH_USERNAME` environment variable to your GitHub username if your GitHub username can't be auto-detected from the `user.email` Git configuration variable.

## Troubleshooting

Currently, most cases should be covered. There may be some edge cases that haven't been addressed to avoid over-complicating the initial versions. Please [create an issue](https://github.com/thebengeu/auto-git-remote-add-upstream/issues/new/choose) for any real-world unhandled cases.
