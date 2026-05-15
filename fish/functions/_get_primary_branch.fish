function _get_primary_branch
    set -l now (date +%s)
    if test -n "$_PRIMARY_BRANCH_CACHE"; and test (math $now - $_PRIMARY_BRANCH_CACHE_TIME) -lt 60
        echo $_PRIMARY_BRANCH_CACHE
        return 0
    end

    set -l result (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
    if test -n "$result"
        set -g _PRIMARY_BRANCH_CACHE $result
    else if git show-ref --verify --quiet refs/heads/main
        set -g _PRIMARY_BRANCH_CACHE main
    else if git show-ref --verify --quiet refs/heads/master
        set -g _PRIMARY_BRANCH_CACHE master
    else
        set -g _PRIMARY_BRANCH_CACHE main
    end

    set -g _PRIMARY_BRANCH_CACHE_TIME $now
    echo $_PRIMARY_BRANCH_CACHE
end
