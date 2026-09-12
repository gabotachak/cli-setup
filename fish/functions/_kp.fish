function _kp
    if test -z "$argv[1]"
        echo "❌ Usage: _kp <pid>"
        return 1
    end
    if ps -p $argv[1] >/dev/null 2>&1
        kill $argv[1]; and echo "✅ Process $argv[1] killed"
    else
        echo "❌ Process $argv[1] not found"
        return 1
    end
end
