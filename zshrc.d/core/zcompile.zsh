function ensure_zcompiled() {
    local file="$1"
    local compiled="$file.zwc"

    if [[ ! -r "$compiled" || "$file" -nt "$compiled" ]]; then
        echo "\033[1;36mCompiling\033[m $file"
        zcompile "$file" &>/dev/null
    fi
}
