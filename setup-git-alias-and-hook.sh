#!/usr/bin/env sh
script_name=add-auto-detected-upstream.sh
local_script=$(dirname "$0")/$script_name
remote_script="https://raw.githubusercontent.com/thebengeu/auto-git-remote-add-upstream/master/$script_name"

if [ -f "$local_script" ]; then
  script=$(cat "$local_script")
else
  script=$(curl -s "$remote_script")
fi

alias=${1:-rau}

git config --global alias."$alias" "!$(
  echo "$script" |
    # Strip shebang line
    tail -n +2 |
    # Strip leading spaces, commented lines and blank lines
    sed -e 's/^ *//' -e '/^\(#.*\)\{0,1\}$/d' |
    # Join lines with newline
    paste -sd '\n'
) #"

template_dir=$(git config --global init.templateDir)

if [ "$template_dir" = "" ]; then
  XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
  template_dir="$XDG_CONFIG_HOME/git/template"
  git config --global init.templateDir "$template_dir"
fi

command="git $alias"
hooks_dir="$template_dir/hooks"
post_checkout="$hooks_dir/post-checkout"

mkdir -p "$hooks_dir"

if [ ! -f "$post_checkout" ]; then
  echo '#!/usr/bin/env sh' >"$post_checkout"
  chmod +x "$post_checkout"
fi

grep -Fqx "$command" "$post_checkout" || echo "$command" >>"$post_checkout"
