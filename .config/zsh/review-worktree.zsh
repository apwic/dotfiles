# Git worktree review workflow.
# Edit this fallback if the workspace ever moves. If this file is sourced from
# inside the workspace, WORKSPACE is auto-detected from the script location.
typeset -g REVIEW_WORKSPACE_FALLBACK="${REVIEW_WORKSPACE_FALLBACK:-/Users/adiyansawicaksana/Stockbit}"

_review_detect_workspace() {
  emulate -L zsh

  if [[ -n "${WORKSPACE:-}" && -d "$WORKSPACE" ]]; then
    print -r -- "$WORKSPACE"
    return 0
  fi

  local script_path="${${(%):-%N}:A}"
  local dir="${script_path:h}"

  while [[ -n "$dir" && "$dir" != "/" ]]; do
    if [[ -d "$dir/infra" && -d "$dir/lib" && -d "$dir/platform" && -d "$dir/securities" ]]; then
      print -r -- "$dir"
      return 0
    fi
    dir="${dir:h}"
  done

  print -r -- "$REVIEW_WORKSPACE_FALLBACK"
}

typeset -g WORKSPACE="${WORKSPACE:-$(_review_detect_workspace)}"

_review_require() {
  emulate -L zsh
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    print -u2 -- "review: required command not found: $cmd"
    return 1
  fi
}

_review_fzf() {
  emulate -L zsh
  local prompt="$1"

  _review_require fzf || return 1
  fzf --prompt="$prompt" --height=40% --reverse
}

_review_safe_name() {
  emulate -L zsh
  local value="$1"

  print -r -- "${value//[^A-Za-z0-9._-]/-}"
}

_review_entry_matches() {
  emulate -L zsh
  local input="$1"
  local repo_rel="$2"
  local branch="$3"
  local worktree_path="$4"
  local worktree_name="${worktree_path:t}"
  local safe_input="$(_review_safe_name "$input")"

  [[ "$worktree_name" == "$input" ]] ||
    [[ "$worktree_name" == "$input-review" ]] ||
    [[ "$worktree_name" == *"$safe_input"* ]] ||
    [[ "${repo_rel:t}" == "$input" ]] ||
    [[ "$repo_rel" == "$input" ]] ||
    [[ "$branch" == "$input" ]] ||
    [[ "${branch:t}" == "$input" ]] ||
    [[ "${branch:t}" == "$safe_input" ]]
}

_review_repo_paths() {
  emulate -L zsh
  local workspace="$1"

  find "$workspace" \
    -path "$workspace/.git" -prune -o \
    -path "$workspace/.reviews" -prune -o \
    -path "$workspace/notes" -prune -o \
    -path "$workspace/logs" -prune -o \
    -name .git -print 2>/dev/null |
    while IFS= read -r git_marker; do
      local repo="${git_marker:h}"
      [[ "$repo" == "$workspace" ]] && continue
      print -r -- "$repo"
    done | sort -u
}

_review_repo_rel_paths() {
  emulate -L zsh
  local workspace="$1"
  local repo

  _review_repo_paths "$workspace" | while IFS= read -r repo; do
    print -r -- "${repo#$workspace/}"
  done
}

_review_resolve_repo() {
  emulate -L zsh
  local workspace="$1"
  local input="$2"
  local candidate

  if [[ -z "$input" ]]; then
    local selected
    selected="$(_review_repo_rel_paths "$workspace" | _review_fzf 'repo> ')"
    [[ -n "$selected" ]] || {
      print -u2 -- "review: no repo selected"
      return 1
    }

    print -r -- "$workspace/$selected"
    return 0
  fi

  candidate="$workspace/$input"
  if [[ -d "$candidate" ]] && git -C "$candidate" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$candidate" rev-parse --show-toplevel
    return 0
  fi

  local matches=()
  local repo
  while IFS= read -r repo; do
    local rel="${repo#$workspace/}"
    if [[ "$rel" == "$input" || "${repo:t}" == "$input" ]]; then
      matches+=("$repo")
    fi
  done < <(_review_repo_paths "$workspace")

  case "${#matches[@]}" in
    0)
      print -u2 -- "review: repo not found: $input"
      return 1
      ;;
    1)
      print -r -- "$matches[1]"
      return 0
      ;;
    *)
      print -u2 -- "review: repo name is ambiguous: $input"
      printf '%s\n' "${matches[@]#$workspace/}" >&2
      return 1
      ;;
  esac
}

_review_default_branch() {
  emulate -L zsh
  local repo="$1"
  local head_ref

  git -C "$repo" remote set-head origin -a >/dev/null 2>&1
  head_ref="$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"

  if [[ -n "$head_ref" ]]; then
    print -r -- "${head_ref#origin/}"
  elif git -C "$repo" show-ref --verify --quiet refs/remotes/origin/main; then
    print -r -- "main"
  elif git -C "$repo" show-ref --verify --quiet refs/remotes/origin/master; then
    print -r -- "master"
  else
    print -u2 -- "review: could not detect default branch; expected origin/main or origin/master"
    return 1
  fi
}

_review_pick_branch() {
  emulate -L zsh
  local repo="$1"
  local input="$2"

  if [[ -n "$input" ]]; then
    print -r -- "${input#origin/}"
    return 0
  fi

  local selected
  selected="$(
    git -C "$repo" branch -r --format='%(refname:short)' |
      sed 's#^origin/##' |
      grep -vE '^(HEAD|origin/HEAD)$' |
      sort -u |
      _review_fzf 'branch> '
  )"

  [[ -n "$selected" ]] || {
    print -u2 -- "review: no branch selected"
    return 1
  }

  print -r -- "$selected"
}

_review_active_worktrees() {
  emulate -L zsh
  local workspace="$1"
  local repo

  _review_repo_paths "$workspace" | while IFS= read -r repo; do
    local repo_rel="${repo#$workspace/}"
    git -C "$repo" worktree list --porcelain 2>/dev/null |
      awk -v workspace="$workspace" -v repo_rel="$repo_rel" '
        function flush() {
          if (path != "" && index(path, workspace "/.reviews/") == 1) {
            if (branch == "") {
              branch = "unknown"
            }
            print repo_rel "\t" branch "\t" path
          }
          path = ""
          branch = ""
        }
        /^worktree / {
          flush()
          path = substr($0, 10)
          next
        }
        /^branch refs\/heads\// {
          branch = substr($0, 19)
          next
        }
        /^detached$/ {
          branch = "(detached)"
          next
        }
        /^$/ {
          flush()
          next
        }
        END {
          flush()
        }
      '
  done
}

review() {
  emulate -L zsh
  _review_require git || return 1
  _review_require nvim || return 1

  local workspace="${WORKSPACE:-$(_review_detect_workspace)}"
  local repo_arg="${1:-}"
  local branch_arg="${2:-}"

  [[ -d "$workspace" ]] || {
    print -u2 -- "review: workspace not found: $workspace"
    return 1
  }

  local repo
  repo="$(_review_resolve_repo "$workspace" "$repo_arg")" || return 1

  local repo_rel="${repo#$workspace/}"
  local repo_name="${repo:t}"
  local reviews_dir="$workspace/.reviews"

  print -- "review: workspace: $workspace"
  print -- "review: repo: $repo_rel"
  print -- "review: fetching origin..."
  git -C "$repo" fetch origin --prune || return 1

  local branch
  branch="$(_review_pick_branch "$repo" "$branch_arg")" || return 1

  if ! git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    print -u2 -- "review: branch not found on origin: $branch"
    return 1
  fi

  local default_branch
  default_branch="$(_review_default_branch "$repo")" || return 1

  local safe_branch="$(_review_safe_name "$branch")"
  local review_path="$reviews_dir/${repo_name}-${safe_branch}-review"
  local review_branch="review/${repo_name}/${safe_branch}"

  if [[ -e "$review_path" ]]; then
    print -u2 -- "review: worktree already exists: $review_path"
    print -u2 -- "review: run 'review-continue ${repo_name}-${safe_branch}-review' to resume it"
    return 1
  fi

  mkdir -p "$reviews_dir" || return 1

  print -- "review: creating worktree: $review_path"
  print -- "review: local branch: $review_branch -> origin/$branch"
  git -C "$repo" worktree add -B "$review_branch" "$review_path" "origin/$branch" || return 1

  print -- "review: opening review Diffview against origin/$default_branch"
  cd "$review_path" || return 1
  nvim -c "ReviewOpen origin/${default_branch}...HEAD"
}

review-done() {
  emulate -L zsh
  _review_require git || return 1

  local workspace="${WORKSPACE:-$(_review_detect_workspace)}"
  local input="${1:-}"

  [[ -d "$workspace" ]] || {
    print -u2 -- "review-done: workspace not found: $workspace"
    return 1
  }

  local active_output="$(_review_active_worktrees "$workspace")"
  local entries=()
  [[ -n "$active_output" ]] && entries=("${(@f)active_output}")
  (( ${#entries[@]} > 0 )) || {
    print -- "review-done: no active review worktrees under $workspace/.reviews"
    cd "$workspace" || return 1
    return 0
  }

  local selected=""
  if [[ -z "$input" ]]; then
    selected="$(printf '%s\n' "${entries[@]}" | column -t -s $'\t' | _review_fzf 'review worktree> ')"
    [[ -n "$selected" ]] || {
      print -u2 -- "review-done: no worktree selected"
      return 1
    }
  else
    local matches=()
    local entry repo_rel rest branch worktree_path
    for entry in "${entries[@]}"; do
      repo_rel="${entry%%	*}"
      rest="${entry#*	}"
      branch="${rest%%	*}"
      worktree_path="${entry##*	}"
      if _review_entry_matches "$input" "$repo_rel" "$branch" "$worktree_path"; then
        matches+=("$entry")
      fi
    done

    case "${#matches[@]}" in
      0)
        print -u2 -- "review-done: no active review worktree matches: $input"
        return 1
        ;;
      1)
        selected="$matches[1]"
        ;;
      *)
        selected="$(printf '%s\n' "${matches[@]}" | column -t -s $'\t' | _review_fzf 'review worktree> ')"
        [[ -n "$selected" ]] || {
          print -u2 -- "review-done: no worktree selected"
          return 1
        }
        ;;
    esac
  fi

  local selected_path="${selected##* }"
  if [[ "$selected" == *$'\t'* ]]; then
    selected_path="${selected##*	}"
  fi

  [[ "$selected_path" == "$workspace/.reviews/"* ]] || {
    print -u2 -- "review-done: refusing to remove non-review path: $selected_path"
    return 1
  }

  local owning_repo=""
  local repo
  while IFS= read -r repo; do
    if git -C "$repo" worktree list --porcelain 2>/dev/null | grep -qxF "worktree $selected_path"; then
      owning_repo="$repo"
      break
    fi
  done < <(_review_repo_paths "$workspace")

  [[ -n "$owning_repo" ]] || {
    print -u2 -- "review-done: could not find owning repo for worktree: $selected_path"
    return 1
  }

  print -- "review-done: removing worktree: $selected_path"
  git -C "$owning_repo" worktree remove --force "$selected_path" || return 1

  print -- "review-done: returning to workspace: $workspace"
  cd "$workspace" || return 1
}

review-list() {
  emulate -L zsh
  _review_require git || return 1

  local workspace="${WORKSPACE:-$(_review_detect_workspace)}"
  local active_output="$(_review_active_worktrees "$workspace")"
  local entries=()
  [[ -n "$active_output" ]] && entries=("${(@f)active_output}")

  if (( ${#entries[@]} == 0 )); then
    print -- "review-list: no active review worktrees under $workspace/.reviews"
    return 0
  fi

  printf '%-35s %-35s %s\n' "REPO" "BRANCH" "PATH"
  printf '%-35s %-35s %s\n' "----" "------" "----"

  local entry repo_rel rest branch worktree_path
  for entry in "${entries[@]}"; do
    repo_rel="${entry%%	*}"
    rest="${entry#*	}"
    branch="${rest%%	*}"
    worktree_path="${entry##*	}"
    printf '%-35s %-35s %s\n' "$repo_rel" "$branch" "$worktree_path"
  done
}

review-continue() {
  emulate -L zsh
  _review_require git || return 1
  _review_require nvim || return 1

  local workspace="${WORKSPACE:-$(_review_detect_workspace)}"
  local input="${1:-}"

  [[ -d "$workspace" ]] || {
    print -u2 -- "review-continue: workspace not found: $workspace"
    return 1
  }

  local active_output="$(_review_active_worktrees "$workspace")"
  local entries=()
  [[ -n "$active_output" ]] && entries=("${(@f)active_output}")
  (( ${#entries[@]} > 0 )) || {
    print -- "review-continue: no active review worktrees under $workspace/.reviews"
    return 1
  }

  local selected=""
  if [[ -z "$input" ]]; then
    selected="$(printf '%s\n' "${entries[@]}" | column -t -s $'\t' | _review_fzf 'continue review> ')"
    [[ -n "$selected" ]] || {
      print -u2 -- "review-continue: no worktree selected"
      return 1
    }
  else
    local matches=()
    local entry repo_rel rest branch worktree_path
    for entry in "${entries[@]}"; do
      repo_rel="${entry%%	*}"
      rest="${entry#*	}"
      branch="${rest%%	*}"
      worktree_path="${entry##*	}"
      if _review_entry_matches "$input" "$repo_rel" "$branch" "$worktree_path"; then
        matches+=("$entry")
      fi
    done

    case "${#matches[@]}" in
      0)
        print -u2 -- "review-continue: no active review worktree matches: $input"
        return 1
        ;;
      1)
        selected="$matches[1]"
        ;;
      *)
        selected="$(printf '%s\n' "${matches[@]}" | column -t -s $'\t' | _review_fzf 'continue review> ')"
        [[ -n "$selected" ]] || {
          print -u2 -- "review-continue: no worktree selected"
          return 1
        }
        ;;
    esac
  fi

  local selected_path="${selected##* }"
  local selected_repo_rel="${selected%% *}"
  if [[ "$selected" == *$'\t'* ]]; then
    selected_path="${selected##*	}"
    selected_repo_rel="${selected%%	*}"
  fi

  [[ "$selected_path" == "$workspace/.reviews/"* ]] || {
    print -u2 -- "review-continue: refusing non-review path: $selected_path"
    return 1
  }

  local repo="$workspace/$selected_repo_rel"
  if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo=""
    local candidate_repo
    while IFS= read -r candidate_repo; do
      if git -C "$candidate_repo" worktree list --porcelain 2>/dev/null | grep -qxF "worktree $selected_path"; then
        repo="$candidate_repo"
        selected_repo_rel="${candidate_repo#$workspace/}"
        break
      fi
    done < <(_review_repo_paths "$workspace")

    [[ -n "$repo" ]] || {
      print -u2 -- "review-continue: original repo not found: $selected_repo_rel"
      return 1
    }
  fi

  local default_branch
  default_branch="$(_review_default_branch "$repo")" || return 1

  print -- "review-continue: repo: $selected_repo_rel"
  print -- "review-continue: worktree: $selected_path"
  print -- "review-continue: opening review Diffview against origin/$default_branch"
  cd "$selected_path" || return 1
  nvim -c "ReviewOpen origin/${default_branch}...HEAD"
}

review-debug() {
  emulate -L zsh

  local workspace="${WORKSPACE:-$(_review_detect_workspace)}"
  print -- "WORKSPACE=$workspace"
  print -- "fzf=$(command -v fzf 2>/dev/null || print -- missing)"
  print -- "nvim=$(command -v nvim 2>/dev/null || print -- missing)"
  print -- "repo count=$(_review_repo_rel_paths "$workspace" | wc -l | tr -d ' ')"
  print -- "first repos:"
  _review_repo_rel_paths "$workspace" | sed -n '1,10p'
}
