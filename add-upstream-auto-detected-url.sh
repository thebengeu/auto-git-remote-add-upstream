#!/usr/bin/env bash
if [ $# -gt 0 ]; then
  git remote add upstream "$@"
  exit $?
fi

if git remote -v | grep -q '^upstream\s'; then
  exit 0
fi

user_email=$(git config user.email)
not_you="^(?!$(git config user.name) <$user_email>$)"
latest_hash_not_yours=$(
  git log --author="$not_you" --format=%H --perl-regexp |
    head -1
)

if [ "$latest_hash_not_yours" = "" ]; then
  exit 0
fi

GH_TOKEN=${GH_TOKEN:-$GITHUB_TOKEN}

if [ "$GH_TOKEN" != "" ]; then
  header_option=(-H "Authorization: Bearer $GH_TOKEN")
fi

base_url='https://api.github.com'
curl_with_options=(curl "${header_option[@]}" -s)

if [ "$GH_USERNAME" = "" ]; then
  # https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-users
  GH_USERNAME=$(
    "${curl_with_options[@]}" "$base_url/search/users?q=$user_email%20in:email" |
      jq -r .items[0].login
  )

  if [ "$GH_USERNAME" = null ]; then
    echo "GitHub username could not be auto-detected from $user_email, set the GH_USERNAME environment variable instead"
    exit 1
  fi
fi

origin_url=$(git ls-remote --get-url origin)

if [[ $origin_url != *github.com*$GH_USERNAME/* ]]; then
  exit 0
fi

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
  # https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-commits
  repo_search_qualifiers=$(
    "${curl_with_options[@]}" "$base_url/search/commits?per_page=100&q=hash:$latest_hash_not_yours" |
      # repo:owner/name+repo:owner/name+...
      jq -r .items[].repository.full_name |
      sed s/^/repo:/ |
      paste -sd + -
  )
  if [ "$repo_search_qualifiers" != "" ]; then
    # https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-repositories
    candidate_metrics=$(
      "${curl_with_options[@]}" "$base_url/search/repositories?per_page=100&q=$repo_search_qualifiers" |
        jq -r '(.items |
              sort_by(.created_at)) as $sorted |
              $sorted[0] as $earliest |
              $sorted[] |
              select(. == $earliest
                or .stargazers_count > $earliest.stargazers_count
                or .forks_count > $earliest.forks_count
                or .open_issues_count > $earliest.open_issues_count
                or .watchers_count > $earliest.watchers_count) |
              "\(.full_name) was created at \(.created_at) and has " +
                "\(.stargazers_count) stars, " +
                "\(.forks_count) forks, " +
                "\(.open_issues_count) open issues and " +
                "\(.watchers_count) watchers"'
    )
    earliest_candidate_metrics=$(echo "$candidate_metrics" | head -1)
    earliest_repo_name=$(echo "$earliest_candidate_metrics" | cut -d ' ' -f 1)

    if [ "$earliest_repo_name" = "$repo_name" ]; then
      exit 0
    fi

    later_candidate_metrics=$(echo "$candidate_metrics" | tail -n +2)
    upstream_url=https://github.com/$earliest_repo_name.git

    echo "Earliest created repo $earliest_candidate_metrics"
    echo

    if [ "$later_candidate_metrics" != "" ]; then
      echo "Repos created later with more stars, forks, open issues or watchers:"
      echo "$later_candidate_metrics"
      echo
    fi
  fi
fi

if [ "$upstream_url" != null ]; then
  git remote add upstream "$upstream_url"
  echo "Ran 'git remote add upstream $upstream_url'"
fi
