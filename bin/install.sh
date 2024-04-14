#!/bin/bash

# Function to clear the screen
clear_screen() {
    printf "\033c"
}

# Function to display error message and wait for a key press
display_error() {
    clear_screen
    echo -e "\033[31mInvalid choice. Please choose 1, 2, 3, or q.\033[m"
    sleep 1
}

# Function to prompt for DOTFILES_DIR
set_dotfiles_dir() {
    while true; do
        clear_screen
        echo -e "\033[0;36mDOTFILES_DIR\033[m is the location where repository will be saved."
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
                break
                ;;
            2)
                echo -e ""
                read -p "Input directory: " DOTFILES_DIR
                echo -e "New directory is: $DOTFILES_DIR"
                break
                ;;
            3)
                break
                ;;
            q)
                exit 0
                ;;
            *)
                display_error
                ;;
        esac
    done
}

# Function to clone repository
clone_repository() {
    clear_screen
    echo -e "Clone repository into \033[0;36mDOTFILES_DIR\033[m..."
    git clone https://github.com/ved0el/dotfiles.git "$DOTFILES_DIR"
    sleep 1
}

# Function to install symbolic links
install() {
    for file in "$DOTFILES_DIR"/*; do
        if [[ -f "$file" ]]; then
            target="$HOME/.$(basename "$file")"
            echo "Linking $file to $target"
            ln -s "$file" "$target"
        fi
    done
}

# Function to remove symbolic links
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

# Function to display setup menu
setup_menu() {
    while true; do
        clear_screen
        echo -e "(1) Install"
        echo -e "(2) Uninstall"
        echo -e "(q) Quit"
        echo -n "Choice [12q]: "
        read -rsn1 choice

        case $choice in
            1)
                install
                ;;
            2)
                uninstall
                ;;
            q)
                exit 0
                ;;
            *)
                display_error
                ;;
        esac

        # Ensure input is one of the allowed choices
        if [[ $choice =~ ^[12q]$ ]]; then
            break
        fi
    done
}

# Function to initialize the setup
initial() {
    clear_screen
    echo -e "Executing \033[0;36mexec zsh\033[m to complete the setup..."
    exec zsh
}

# Main function
main() {
    set_dotfiles_dir
    clone_repository
    setup_menu
    initial
}

# Run the main function
main
