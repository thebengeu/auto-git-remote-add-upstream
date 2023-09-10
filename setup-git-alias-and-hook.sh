#!/usr/bin/env sh
alias=${1:-rau}
template_dir=$(git config --global init.templateDir)

if [ "$template_dir" = "" ]; then
  XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
  template_dir="$XDG_CONFIG_HOME/git/template"
  echo "Setting template directory to $template_dir in global Git config"
  echo
  git config --global init.templateDir "$template_dir"
fi

hooks_dir="$template_dir/hooks"
script_name=add-upstream-auto-detected-url.sh
script_dest_path="$hooks_dir/$script_name"
local_script=$(dirname "$0")/$script_name

mkdir -p "$hooks_dir"

if [ -f "$local_script" ]; then
  cp "$local_script" "$hooks_dir"
  echo "Copied $local_script to $hooks_dir"
else
  remote_script="https://raw.githubusercontent.com/thebengeu/auto-git-remote-add-upstream/master/$script_name"
  curl -s "$remote_script" >"$script_dest_path"
  echo "Downloaded $remote_script to $script_dest_path"
fi

echo

chmod +x "$script_dest_path"

post_checkout_path="$hooks_dir/post-checkout"

if [ ! -f "$post_checkout_path" ]; then
  echo '#!/usr/bin/env sh' >"$post_checkout_path"
  chmod +x "$post_checkout_path"
fi

grep -q "$script_name" "$post_checkout_path" ||
  echo ".git/hooks/$script_name && sed -i'' /$script_name/d .git/hooks/post-checkout" >>"$post_checkout_path"

echo "$post_checkout_path now contains:"
cat "$post_checkout_path"
echo

git config --global alias."$alias" "!$script_dest_path"

echo "Set '$alias' Git alias to '!$script_dest_path'"
