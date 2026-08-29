function gitc
    set -l primary (_get_primary_branch)
    git checkout $primary; or return 1
    for branch in (git branch --merged $primary | string replace -r '^\*?\s*' '' | string trim)
        test -z "$branch"; and continue
        test "$branch" = "$primary"; and continue
        git branch -d $branch
    end
    echo "✅ Cleaned up merged branches"
end
