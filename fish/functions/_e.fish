function _e
    set -l primary (_get_primary_branch)
    _gc $primary; and git branch -D $argv[1]; and echo "✅ Branch deleted and switched to $primary"
end
