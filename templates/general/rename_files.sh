#regex='prefix - (.*) - suffix.txt'
regex='Spanish_A4-(.*)'
for f in *.{tex,html}; do
    [[ $f =~ $regex ]] && mv "$f" "${BASH_REMATCH[1]}"
done
