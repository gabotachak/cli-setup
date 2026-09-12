function _br
    if test -z "$argv[1]"
        echo "❌ Usage: _br <branch>"
        return 1
    end
    set -l primary (_get_primary_branch)
    _gc $primary; and \
        git fetch origin $argv[1]; and echo "📥 Fetched from origin/$argv[1]"; and \
        git checkout $argv[1]; and \
        git merge "origin/$argv[1]"; and echo "📍 Checked out and merged $argv[1]"
end
