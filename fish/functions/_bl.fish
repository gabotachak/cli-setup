function _bl
    if test -z "$argv[1]"
        echo "❌ Usage: _bl <branch>"
        return 1
    end
    set -l primary (_get_primary_branch)
    _gc $primary; and \
        git branch $argv[1]; and echo "✅ Branch created: $argv[1]"; and \
        git push --set-upstream origin $argv[1]; and echo "🚀 Pushed to origin"; and \
        git checkout $argv[1]; and echo "📍 Checked out $argv[1]"
end
