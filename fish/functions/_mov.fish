function _mov
    echo "📁 Moving to: $argv[1]"
    cd $argv[1]; or return 1
end
