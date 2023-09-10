#!/usr/bin/env bash
if [ $# -gt 0 ]; then
  git remote add upstream "$@"
  exit $?
fi

if git remote -v | grep '^upstream\t'; then
  exit 0
fi

GH_TOKEN=${GH_TOKEN:-$GITHUB_TOKEN}

if [ "$GH_TOKEN" != "" ]; then
  header_option=(-H "Authorization: Bearer $GH_TOKEN")
fi

base_url='https://api.github.com'
curl_with_options=(curl "${header_option[@]}" -s)
user_email=$(git config user.email)

if [ "$GH_USERNAME" = "" ]; then
  # https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-users
  GH_USERNAME=$(
    "${curl_with_options[@]}" "$base_url/search/users?q=$user_email%20in:email" |
      jq -r .items[0].login
  )
fi

origin_url=$(git ls-remote --get-url origin)

if [[ $origin_url = *github.com*$GH_USERNAME/* ]]; then
  repo_name=$(
    echo "$origin_url" |
      sed 's/\.git$//' |
      sed 's/.*[/:]\(.*\/.*\)$/\1/'
  )
  # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository
  upstream_url=$(
    "${curl_with_options[@]}" "$base_url/repos/$repo_name" |
      jq -r .parent.clone_url
  )

  if [ "$upstream_url" = null ]; then
    not_you="^(?!$(git config user.name) <$user_email>$)"
    latest_hash_not_yours=$(
      git log --author="$not_you" --format=%H --perl-regexp --reverse |
        head -1
    )

    if [ "$latest_hash_not_yours" != "" ]; then
      # https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-commits
      repo_search_qualifiers=$(
        "${curl_with_options[@]}" "$base_url/search/commits?per_page=100&q=hash:$latest_hash_not_yours" |
          # repo:owner/name+repo:owner/name+...
          jq -r .items[].repository.full_name |
          sed s/^/repo:/ |
          paste -sd + -
      )
      # https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-repositories
      upstream_url=$(
        "${curl_with_options[@]}" "$base_url/search/repositories?per_page=100&q=$repo_search_qualifiers" |
          jq -r '.items |
          sort_by(.stargazers_count, .watchers_count, .forks_count, .open_issues_count) |
          reverse |
          .[0].clone_url'
      )
    fi
  fi

  if [ "$upstream_url" != null ]; then
    set -x
    git remote add upstream "$upstream_url"
  fi
fi
