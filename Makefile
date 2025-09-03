# Dotfiles Development Makefile
# Quick commands for common development tasks

.PHONY: help install test debug docker docker-build docker-run docker-shell validate perf clean

# Default target
help:
	@echo "🔧 Dotfiles Development Commands"
	@echo ""
	@echo "Installation:"
	@echo "  make install          - Install dotfiles"
	@echo "  make update           - Update dotfiles"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make test             - Run full test suite"
	@echo "  make validate         - Validate configuration"
	@echo "  make perf             - Performance testing"
	@echo ""
	@echo "Docker Testing:"
	@echo "  make docker-build     - Build Docker test image"
	@echo "  make docker-run       - Run Docker tests"
	@echo "  make docker-shell     - Start Docker shell"
	@echo ""
	@echo "Development:"
	@echo "  make debug            - Interactive debug menu"
	@echo "  make info             - System information"
	@echo "  make clean            - Clean caches and temp files"
	@echo ""
	@echo "Examples:"
	@echo "  make docker-build && make docker-run"
	@echo "  make validate && make perf"

# Installation
install:
	./bin/dotfiles install

update:
	./bin/dotfiles update

# Testing
test:
	./bin/dotfiles-debug test

validate:
	./bin/dotfiles-debug validate all

perf:
	./bin/dotfiles-debug perf startup

# Docker
docker-build:
	./bin/dotfiles-debug docker build

docker-run:
	./bin/dotfiles-debug docker run test

docker-shell:
	./bin/dotfiles-debug docker shell

docker-compose:
	docker-compose up

# Development
debug:
	./bin/dotfiles debug

info:
	./bin/dotfiles-debug info

# Cleanup
clean:
	@echo "🧹 Cleaning caches and temporary files..."
	rm -rf ~/.cache/sheldon/cache.zsh
	rm -rf ~/.cache/p10k/p10k-instant-prompt-*.zsh
	rm -rf ~/.cache/dotfiles
	rm -f *.zwc
	rm -f **/*.zwc
	rm -f /tmp/dotfiles-debug-*.log
	@echo "✅ Cleanup completed"

# Docker cleanup
docker-clean:
	./bin/dotfiles-debug docker clean

# Full development cycle
dev-cycle: validate perf test

# Pre-commit checks
pre-commit: validate perf
	@echo "✅ Pre-commit checks passed"
