# 🔧 Dotfiles Debug Tools

Comprehensive debugging and testing utilities for dotfiles development.

## 🚀 Quick Start

```bash
# Run interactive debug menu
./bin/dotfiles debug

# Run specific debug command
./bin/dotfiles debug validate all

# Test with Docker
./bin/dotfiles-debug docker build
./bin/dotfiles-debug docker shell
```

## 🐳 Docker Testing Environment

Test your dotfiles in an isolated environment before committing.

### Build and Run

```bash
# Build Docker image
./bin/dotfiles-debug docker build

# Start interactive shell for debugging
./bin/dotfiles-debug docker shell

# Run automated tests
./bin/dotfiles-debug docker run test

# Install and test
./bin/dotfiles-debug docker run install
```

### Docker Compose (Multiple Profiles)

```bash
# Test all profiles
docker-compose up

# Test specific profile
docker-compose up dotfiles-minimal
docker-compose up dotfiles-server
docker-compose up dotfiles-develop

# Run in background
docker-compose up -d dotfiles-test
```

### Docker Commands

| Command | Description |
|---------|-------------|
| `docker build` | Build test image |
| `docker shell` | Interactive shell |
| `docker run <cmd>` | Run command (install/test/debug) |
| `docker compose` | Multi-profile testing |
| `docker clean` | Clean Docker resources |

## ⚡ Performance Testing

Measure and optimize shell startup performance.

```bash
# Test shell startup times
./bin/dotfiles-debug perf startup

# Test package loading performance
./bin/dotfiles-debug perf packages

# Test Zsh compilation
./bin/dotfiles-debug perf compilation

# Check cache sizes
./bin/dotfiles-debug perf cache
```

## ✅ Configuration Validation

Validate your dotfiles configuration.

```bash
# Validate everything
./bin/dotfiles-debug validate all

# Validate specific components
./bin/dotfiles-debug validate zshrc
./bin/dotfiles-debug validate packages
./bin/dotfiles-debug validate symlinks
./bin/dotfiles-debug validate permissions
```

## 🧪 Automated Test Suite

Run comprehensive tests before committing.

```bash
# Run all tests
./bin/dotfiles-debug test

# This will:
# - Validate configuration
# - Test performance
# - Check package loading
```

## 📊 System Information

Get detailed system information.

```bash
./bin/dotfiles-debug info
```

Shows:
- OS and shell information
- Installed tools status
- Profile and configuration
- Cache locations

## 🎯 Development Workflow

### Before Committing

1. **Validate Configuration**
   ```bash
   ./bin/dotfiles-debug validate all
   ```

2. **Test Performance**
   ```bash
   ./bin/dotfiles-debug perf startup
   ```

3. **Docker Testing**
   ```bash
   ./bin/dotfiles-debug docker build
   ./bin/dotfiles-debug docker run test
   ```

4. **Run Full Test Suite**
   ```bash
   ./bin/dotfiles-debug test
   ```

### Debugging Issues

1. **Check System Info**
   ```bash
   ./bin/dotfiles-debug info
   ```

2. **Validate Specific Components**
   ```bash
   ./bin/dotfiles-debug validate packages
   ./bin/dotfiles-debug validate symlinks
   ```

3. **Performance Analysis**
   ```bash
   ./bin/dotfiles-debug perf startup
   ./bin/dotfiles-debug perf packages
   ```

4. **Interactive Docker Debugging**
   ```bash
   ./bin/dotfiles-debug docker shell
   ```

## 🛠️ Available Commands

### Main Commands
- `docker` - Docker testing environment
- `perf` - Performance testing
- `validate` - Configuration validation
- `info` - System information
- `test` - Run test suite

### Docker Subcommands
- `build` - Build Docker image
- `run <cmd>` - Run command in container
- `shell` - Interactive shell
- `compose` - Docker Compose testing
- `clean` - Clean resources

### Performance Subcommands
- `startup` - Shell startup times
- `packages` - Package loading performance
- `compilation` - Zsh file compilation
- `cache` - Cache analysis

### Validation Subcommands
- `all` - Full validation
- `zshrc` - Zsh configuration
- `packages` - Package scripts
- `symlinks` - Symlink validation
- `permissions` - File permissions

## 🔧 Interactive Mode

Run without arguments for interactive menu:

```bash
./bin/dotfiles-debug
```

Navigate through menus to access all debugging features.

## 📝 Log Files

All debug output is saved to:
```
/tmp/dotfiles-debug-YYYYMMDD-HHMMSS.log
```

Check the log file for detailed debugging information.

## 🚨 Troubleshooting

### Common Issues

1. **Docker not found**
   ```bash
   # Install Docker
   brew install docker  # macOS
   sudo apt install docker.io  # Ubuntu
   ```

2. **Permission denied**
   ```bash
   # Make scripts executable
   chmod +x bin/dotfiles-debug
   ```

3. **Validation errors**
   ```bash
   # Check specific component
   ./bin/dotfiles-debug validate packages
   ```

4. **Slow performance**
   ```bash
   # Clear caches and retest
   rm -rf ~/.cache/sheldon ~/.cache/p10k
   ./bin/dotfiles-debug perf startup
   ```

## 📋 Best Practices

1. **Always test before committing**
2. **Use Docker for isolated testing**
3. **Check performance regularly**
4. **Validate configuration changes**
5. **Review log files for issues**
6. **Test all profiles**

## 🎯 Integration with Git

Add to your Git hooks for automated testing:

```bash
# .git/hooks/pre-commit
#!/bin/bash
./bin/dotfiles-debug validate all
./bin/dotfiles-debug perf startup
```

## 📞 Support

For issues or questions:
1. Check the debug log file
2. Run `./bin/dotfiles-debug info`
3. Use Docker for isolated testing
4. Review this documentation

---

Happy debugging! 🐛✨
