function _gcc
    set -l primary (_get_primary_branch)
    git checkout $primary -- $argv[1]
end
