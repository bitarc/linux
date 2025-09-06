find . -depth -name '* *' | while IFS= read -r file; do
    mv -- "$file" "${file// /_}"
done
find . -depth -name "*'*" | while IFS= read -r file; do
    mv -- "$file" "${file//\'/_}"
done

