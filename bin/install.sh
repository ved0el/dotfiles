#!/bin/bash

# Create symbolic links
install() {
    for file in "$DOTFILES_DIR"/*; do
        if [[ -f "$file" ]]; then
            target="$HOME/.$(basename "$file")"
            echo "Linking $file to $target"
            ln -s "$file" "$target"
        fi
    done
}

# Remove symbolic links
uninstall() {
    for file in "$DOTFILES_DIR"/*; do
        if [[ -f "$file" ]]; then
            target="$HOME/.$(basename "$file")"
            if [[ -L "$target" && $(readlink -f "$target") == "$(realpath "$file")" ]]; then
                rm "$target"
                echo "Removed link $target"
            fi
        fi
    done

    # Remove repository folder
    rm -rf "$DOTFILES_DIR"
}

set_dotfiles_dir(){
    while true; do
        clear
        echo -e "\033[0;36mDOTFILES_DIR\033[m is the location where repogitory will be saved."
        echo -e "Current value is: \033[0;36m$DOTFILES_DIR\033[m"
        echo -e ""
        echo -e "Do you want to change it?"
        echo -e ""
        echo -e "(1) Default (\033[0;36m\$HOME/.dotfiles\033[m)."
        echo -e "(2) Yes."
        echo -e "(3) No."
        echo -e "(q) Quit and do nothing."
        echo -n "Choice [123q]: "
        read -rsn1 choice

        case $choice in
            1)
                export DOTFILES_DIR="$HOME/.dotfiles"
                ;;
            2)
                echo -e ""
                read -p "Input directory: " input
                echo -e "New directory is: " $input
                # export DOTFILES_DIR="$input"
                ;;
            3)
                ;;
            q)
                clear
                exit 0
                ;;
            *)
                ;;
        esac

        # Ensure input is one of the allowed choices
        if [[ $choice =~ ^[123q]$ ]]; then
            break
        fi
    done
}

clone_repository(){
    clear
    echo -e "Clone repository into \033[0;36mDOTFILES_DIR\033[m..."
    git clone https://github.com/ved0el/dotfiles.git $DOTFILES_DIR
}

setup_menu(){
    while true; do
        clear
        echo -e "(1) Install"
        echo -e "(2) Uninstall"
        echo -e "(q) Quit"
        echo -n "Choice [123q]: "
        read -rsn1 choice

        case $choice in
            1)
                install
                ;;
            2)
                uninstall
                ;;
            q)
                clear
                exit 0
                ;;
            *)
                ;;
        esac

        # Ensure input is one of the allowed choices
        if [[ $choice =~ ^[12q]$ ]]; then
            break
        fi
    done
}

initial(){
    echo -e "Executing \033[0;36mexec zsh\033[m to complete the setup..."
    exec zsh
}

# main
set_dotfiles_dir
clone_repository
setup_menu
initial
