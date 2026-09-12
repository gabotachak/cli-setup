function _p
    if test -z "$argv[1]"
        echo "❌ Usage: _p <port_pattern>"
        return 1
    end
    lsof -nP -iTCP -sTCP:LISTEN | grep $argv[1]
end
