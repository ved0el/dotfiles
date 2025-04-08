#!/bin/bash

# Function to clear the screen
clear_screen() {
  printf "\033c"
}

# Function to display error message
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
        if [ -z "$DOTFILES_DIR" ] || [ ! -d "$DOTFILES_DIR" ]; then
          echo -e "\033[31mInvalid directory. Please provide a valid directory.\033[m"
          sleep 1
        else
          echo -e "New directory is: $DOTFILES_DIR"
          break
        fi
        ;;
      3)
        break
        ;;
      q)
        echo -e ""
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
  echo -e "Cloning repository into \033[0;36m$DOTFILES_DIR\033[m..."
  if git clone https://github.com/ved0el/dotfiles.git "$DOTFILES_DIR"; then
    echo -e "\033[32mRepository cloned successfully.\033[m"
  else
    echo -e "\033[31mFailed to clone the repository. Please check the URL or your connection.\033[m"
    exit 1
  fi
  sleep 1
}

# Function to fetch repository
fetch_repository() {
  clear_screen
  echo -e "Fetching latest commit..."
  cd $DOTFILES_DIR || exit
  git pull
}

# Function to install symbolic links
install() {
  for file in "$DOTFILES_DIR"/*; do
    if [[ -f "$file" ]]; then
      target="$HOME/.$(basename "$file")"
      if [[ -e "$target" ]]; then
        read -p "File $target already exists. Overwrite? (y/n): " overwrite
        if [[ $overwrite != "y" ]]; then
          echo "Skipping $target"
          continue
        fi
      fi
      echo "Linking $file to $target"
      ln -sf "$file" "$target"
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

  # Confirm before removing repository folder
  read -p "Do you want to remove the repository folder $DOTFILES_DIR? (y/n): " remove_repo
  if [[ $remove_repo == "y" ]]; then
    rm -rf "$DOTFILES_DIR"
    echo "Removed repository folder $DOTFILES_DIR"
  fi
}

# Function to re-link symbolic links
relink() {

  clear_screen
  echo -e "Re-linking dotfiles..."

  for file in "$HOME/.dotfiles"/*; do
    if [[ -f "$file" ]]; then
      target="$HOME/.$(basename "$file")"
      if [[ -e "$target" ]]; then
        read -p "File $target already exists. Overwrite? (y/n): " overwrite
        if [[ $overwrite != "y" ]]; then
          echo "Skipping $target"
          continue
        fi
      fi
      echo "Re-linking $file to $target"
      ln -sf "$file" "$target"
    fi
  done

  echo -e "\033[32mAll files have been re-linked.\033[m"
  sleep 1
}

# Function to display setup menu
setup_menu() {
  while true; do
    clear_screen
    echo -e "(1) Install"
    echo -e "(2) Update"
    echo -e "(3) Re-link"
    echo -e "(4) Uninstall"
    echo -e "(5) Quit"
    echo -n "Choice [12345]: "
    read -rsn1 choice

    case $choice in
      1)
        set_dotfiles_dir
        clone_repository
        install
        ;;
      2)
        fetch_repository
        install
        ;;
      3)
        relink
        ;;
      4)
        uninstall
        ;;
      5)
        echo -e ""
        exit 0
        ;;
      *)
        display_error
        ;;
    esac

    # Ensure input is one of the allowed choices
    if [[ $choice =~ ^[12345]$ ]]; then
      break
    fi
  done
}

# Function to initialize the setup
initial() {
  clear_screen
  echo -e "Executing \033[0;36mexec zsh\033[m to complete the setup..."
  if command -v zsh >/dev/null 2>&1; then
    exec zsh
  else
    echo -e "\033[31mZsh is not installed. Please install it and run the script again.\033[m"
    exit 1
  fi
}

# Main function
main() {
  setup_menu
  initial
}

# Run the main function
main
