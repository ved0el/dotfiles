# Windows-only — run from Git Bash with `make <target>`.
# macOS / Linux users: use bin/dotfiles (this Makefile hard-fails there).

UNAME := $(shell uname -s)
ifeq ($(filter MINGW% MSYS% CYGWIN%, $(UNAME)),)
  $(error This Makefile is Windows-only ($(UNAME) detected). Use bin/dotfiles on macOS/Linux.)
endif

DOTFILES   := $(CURDIR)
CONFIG_DIR := $(DOTFILES)/config
TARGET     := $(HOME)/.config
CLAUDE_TGT := $(HOME)/.claude

# Auto-discover. Skip macOS-only daemons + the special-cased claude/.
EXCLUDE      := claude skhd yabai
PACKAGES     := $(filter-out $(EXCLUDE),$(notdir $(wildcard $(CONFIG_DIR)/*)))
CLAUDE_FILES := $(notdir $(wildcard $(CONFIG_DIR)/claude/*))

export MSYS = winsymlinks:nativestrict

.DEFAULT_GOAL := help
.PHONY: help link unlink verify doctor

help:           ## list targets and discovered tools
	@awk 'BEGIN{FS=":.*##"} /^[a-z-]+:.*##/ {printf "  %-10s %s\n",$$1,$$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "  config dirs : $(PACKAGES)"
	@echo "  claude files: $(CLAUDE_FILES)"

link:           ## create / refresh all symlinks (idempotent — safe to re-run)
	@mkdir -p "$(TARGET)" "$(CLAUDE_TGT)"
	@for pkg in $(PACKAGES); do \
	  dst="$(TARGET)/$$pkg"; src="$(CONFIG_DIR)/$$pkg"; \
	  if [ -L "$$dst" ]; then rm -f "$$dst"; \
	  elif [ -e "$$dst" ]; then echo "  SKIP  $$dst exists and is not a symlink"; continue; fi; \
	  ln -s "$$src" "$$dst" && echo "  link  $$dst -> $$src"; \
	done
	@for f in $(CLAUDE_FILES); do \
	  dst="$(CLAUDE_TGT)/$$f"; src="$(CONFIG_DIR)/claude/$$f"; \
	  if [ -L "$$dst" ]; then rm -f "$$dst"; \
	  elif [ -e "$$dst" ]; then echo "  SKIP  $$dst exists and is not a symlink"; continue; fi; \
	  ln -s "$$src" "$$dst" && echo "  link  $$dst -> $$src"; \
	done

unlink:         ## remove every symlink we created (only touches symlinks)
	@for pkg in $(PACKAGES); do \
	  dst="$(TARGET)/$$pkg"; \
	  [ -L "$$dst" ] && rm -f "$$dst" && echo "  rm    $$dst"; \
	done; true
	@for f in $(CLAUDE_FILES); do \
	  dst="$(CLAUDE_TGT)/$$f"; \
	  [ -L "$$dst" ] && rm -f "$$dst" && echo "  rm    $$dst"; \
	done; true

verify:         ## report status of every expected link (OK / MISSING / STALE / CONFLICT)
	@status=0; \
	for pkg in $(PACKAGES); do \
	  dst="$(TARGET)/$$pkg"; src="$(CONFIG_DIR)/$$pkg"; \
	  if [ -L "$$dst" ]; then \
	    if [ "$$dst" -ef "$$src" ]; then echo "  OK        $$dst"; \
	    else echo "  STALE     $$dst -> $$(readlink "$$dst")"; status=1; fi; \
	  elif [ -e "$$dst" ]; then echo "  CONFLICT  $$dst (not a symlink)"; status=1; \
	  else echo "  MISSING   $$dst"; status=1; fi; \
	done; \
	for f in $(CLAUDE_FILES); do \
	  dst="$(CLAUDE_TGT)/$$f"; src="$(CONFIG_DIR)/claude/$$f"; \
	  if [ -L "$$dst" ]; then \
	    if [ "$$dst" -ef "$$src" ]; then echo "  OK        $$dst"; \
	    else echo "  STALE     $$dst -> $$(readlink "$$dst")"; status=1; fi; \
	  elif [ -e "$$dst" ]; then echo "  CONFLICT  $$dst (not a symlink)"; status=1; \
	  else echo "  MISSING   $$dst"; status=1; fi; \
	done; \
	exit $$status

doctor:         ## check that real Windows symlinks work in this shell
	@if [ -z "$$MSYS" ] || ! echo "$$MSYS" | grep -q winsymlinks; then \
	  echo "  warn  MSYS env var doesn't include winsymlinks — add to ~/.bashrc: export MSYS=winsymlinks:nativestrict"; \
	fi
	@tmp=$$(mktemp); ln -s "$$tmp" "$$tmp.lnk" 2>/dev/null && [ -L "$$tmp.lnk" ] && \
	  echo "  ok    native symlinks work" && rm -f "$$tmp" "$$tmp.lnk" || \
	  { echo "  fail  native symlinks unavailable — enable Windows Developer Mode (Settings -> For developers)"; rm -f "$$tmp" "$$tmp.lnk"; exit 1; }
