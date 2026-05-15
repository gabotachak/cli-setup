function gitc
    set -l primary (_get_primary_branch)
    git checkout $primary; or return 1
    for branch in (git branch --merged $primary | grep -v -E "^\*|$primary" | string trim)
        git branch -d $branch
    end
    echo "✅ Cleaned up merged branches"
end
