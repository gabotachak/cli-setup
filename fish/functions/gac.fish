function gac
    if test -z "$argv[1]"
        echo "Error: Commit message is required"
        echo "Usage: gac 'your commit message'"
        return 1
    end
    git add . && git commit -m "$argv[1]"
end
