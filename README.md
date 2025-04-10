# dotfiles - Simplify Your Environment

Effortlessly manage and configure your development or server environment with `dotfiles`. This repository helps you set up, customize, and manage your shell environment and essential tools.

---

## 🚀 Features

- **Easy Installation**: Minimal or full installation options are available.
- **Profiles for Different Use Cases**:
  - **Minimal**: Basic setup with shell configuration.
  - **Server**: Shell + utilities for server environments.
  - **Full**: Complete setup for a development machine.
- **Fully Configurable**: Environment variables like `DOTFILES_PROFILE` and `DOTFILES_ROOT` allow full customization.
- **Safe and Clean**: Includes an easy uninstallation option to revert changes at any time.

---

## 📥 Installation

### Quick Install (Minimal Setup)

Run the following command to install `dotfiles` in **minimal mode**, providing a basic shell configuration:

```bash
curl -fsSL https://raw.githubusercontent.com/ved0el/dotfiles/main/bin/install.sh | bash
```

Alternatively, you can customize the installation by using environment variables:

```bash
DOTFILES_PROFILE=minimal DOTFILES_ROOT=$HOME/mydotfiles \
  curl -fsSL https://raw.githubusercontent.com/ved0el/dotfiles/main/bin/install.sh | bash
```

---

### Interactive Install (Full Options)

For a more customizable and interactive installation, download and execute the installer manually:

```bash
# Download installer
curl -o install.sh https://raw.githubusercontent.com/ved0el/dotfiles/main/bin/install.sh

# Make it executable
chmod +x install.sh

# Run the installer
./install.sh
```

The interactive mode will allow you to:

- Choose the installation **profile** (`minimal`, `server`, `full`).
- Set or confirm the target directory for the dotfiles.

---

## ⚙️ Profiles

The installer supports the following setup profiles, catering to different use cases:

| **Profile** | **Description**                                                                |
| ----------- | ------------------------------------------------------------------------------ |
| `minimal`   | Sets up a basic shell configuration (default).                                 |
| `server`    | Installs shell configuration and essential utilities for server environments.  |
| `full`      | Installs everything for a complete development machine setup, including tools. |

To specify a profile, set the `DOTFILES_PROFILE` environment variable before running the installer, e.g.,:

```bash
DOTFILES_PROFILE=full curl -fsSL https://raw.githubusercontent.com/ved0el/dotfiles/main/bin/install.sh | bash
```

---

## 🛠 Customization

You can customize your installation with the following options:

| **Environment Variable** | **Default**       | **Description**                                      |
| ------------------------ | ----------------- | ---------------------------------------------------- |
| `DOTFILES_ROOT`          | `$HOME/.dotfiles` | The directory where dotfiles are cloned and managed. |
| `DOTFILES_PROFILE`       | `minimal`         | The installation profile to use.                     |

For example:

```bash
DOTFILES_PROFILE=server DOTFILES_ROOT=$HOME/custom-dotfiles \
  curl -fsSL https://raw.githubusercontent.com/ved0el/dotfiles/main/bin/install.sh | bash
```

---

## 🔄 Updating Dotfiles

To update to the latest configuration, simply re-run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/ved0el/dotfiles/main/bin/install.sh | bash
```

Or, if cloned manually:

```bash
cd $DOTFILES_ROOT
git pull
./install.sh
```

---

## 🧹 Uninstalling

If you want to remove the dotfiles and revert your environment:

1. Run the uninstaller via the interactive menu:

   ```bash
   ./install.sh
   ```

2. Select the `Uninstall` option to:
   - Remove all symlinks created by the script.
   - Delete the dotfiles repository.
   - Clean up relevant entries in `.zshenv`.

Alternatively, for non-interactive uninstallation:

```bash
DOTFILES_ROOT=$HOME/.dotfiles bash -c 'source $DOTFILES_ROOT/bin/install.sh && do_uninstall'
```

---

## 📝 Notes

- Ensure `git`, `curl`, and `sudo` are installed on your system before running the installer.
- After installation, your shell configuration will automatically load the new `.zshenv` file.
- For more details, read the [source code](https://github.com/ved0el/dotfiles).

---

## 💡 Troubleshooting

If you encounter issues:

1. Verify all required dependencies are installed (`git`, `curl`, `bash`).
2. Check if the environment variables `DOTFILES_PROFILE` and `DOTFILES_ROOT` are set correctly.
3. Review the installation log output for error messages.
4. Open an issue on GitHub: https://github.com/ved0el/dotfiles/issues

---

## 📄 License

This project is distributed under the MIT License. See the LICENSE file for more information.

---

## 🙌 Contributing

Contributions to `dotfiles` are welcome! If you:

- Have improvements or suggestions.
- Want to add support for new tools.
- Discover bugs to fix.

Please open an issue or submit a pull request.

---
