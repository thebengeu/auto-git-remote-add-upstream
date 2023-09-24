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
script_src_dir=$(dirname "$0")

script_name=add-upstream-auto-detected-url.sh
script_dest_path="$hooks_dir/$script_name"
script_src_path=$script_src_dir/$script_name

mkdir -p "$hooks_dir"
cp "$script_src_path" "$script_dest_path"
chmod +x "$script_dest_path"

echo "Copied $script_src_path to $hooks_dir"
echo

post_checkout_src_path="$script_src_dir/post-checkout"
post_checkout_dest_path="$hooks_dir/post-checkout"

if [ ! -f "$post_checkout_dest_path" ]; then
  cp "$post_checkout_src_path" "$post_checkout_dest_path"
  chmod +x "$post_checkout_dest_path"
elif ! grep -q "$script_name" "$post_checkout_dest_path"; then
  tail -n +2 "$post_checkout_src_path" >>"$post_checkout_dest_path"
fi

echo "$post_checkout_dest_path now contains:"
echo
cat "$post_checkout_dest_path"
echo

git config --global alias."$alias" "!$script_dest_path"

echo "Set '$alias' Git alias to '!$script_dest_path'"
