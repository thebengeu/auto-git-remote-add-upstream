#!/usr/bin/env sh
alias=${1:-rau}
script_name=add-upstream-auto-detected-url.sh
local_script=$(dirname "$0")/$script_name
set_alias_message="Setting '$alias' Git alias for one-liner transformation of"

if [ -f "$local_script" ]; then
  script=$(cat "$local_script")
  echo "$set_alias_message $local_script"
else
  remote_script="https://raw.githubusercontent.com/thebengeu/auto-git-remote-add-upstream/master/$script_name"
  script=$(curl -s "$remote_script")
  echo "$set_alias_message $remote_script"
fi

echo

git config --global alias."$alias" "!$(
  echo "$script" |
    # Strip shebang line
    tail -n +2 |
    # Strip leading spaces, commented lines and blank lines
    sed -e 's/^ *//' -e '/^\(#.*\)\{0,1\}$/d' |
    # Join lines with newline
    paste -sd '\n' -
) #"

template_dir=$(git config --global init.templateDir)

if [ "$template_dir" = "" ]; then
  XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
  template_dir="$XDG_CONFIG_HOME/git/template"
  echo "Setting template directory to $template_dir in global Git config"
  echo
  git config --global init.templateDir "$template_dir"
fi

command="git $alias"
hooks_dir="$template_dir/hooks"
post_checkout_path="$hooks_dir/post-checkout"

mkdir -p "$hooks_dir"

if [ ! -f "$post_checkout_path" ]; then
  echo '#!/usr/bin/env sh' >"$post_checkout_path"
  chmod +x "$post_checkout_path"
fi

grep -Fqx "$command" "$post_checkout_path" || echo "$command" >>"$post_checkout_path"

echo "$post_checkout_path now contains:"
cat "$post_checkout_path"
