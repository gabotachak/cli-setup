function _get_primary_branch
    # No cache: symbolic-ref / show-ref are local file reads (sub-millisecond),
    # and a cache that isn't keyed per repo returns the wrong branch after `cd`.
    set -l result (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
    if test -n "$result"
        echo $result
    else if git show-ref --verify --quiet refs/heads/main
        echo main
    else if git show-ref --verify --quiet refs/heads/master
        echo master
    else
        echo main
    end
end
