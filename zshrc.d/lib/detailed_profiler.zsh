#!/usr/bin/env zsh

# =============================================================================
# Detailed Startup Time Profiler - Microsecond precision timing
# =============================================================================

# Enable detailed profiling if DOTFILES_PROFILE_STARTUP is set
if [[ "${DOTFILES_PROFILE_STARTUP:-false}" == "true" ]]; then
    # Start profiling with high precision
    typeset -g __STARTUP_PROFILE_START=$(date +%s.%N)
    typeset -g __STARTUP_PROFILE_TIMES=()
    typeset -g __STARTUP_PROFILE_DETAILED=()
    
    # Function to log timing with microsecond precision
    profile_log() {
        local message="$1"
        local current_time=$(date +%s.%N)
        local elapsed=$(echo "$current_time - $__STARTUP_PROFILE_START" | bc -l 2>/dev/null || echo "0")
        __STARTUP_PROFILE_TIMES+=("${elapsed}s: $message")
        [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "⏱️  ${elapsed}s: $message"
    }
    
    # Function to log debug timing (always shows when DOTFILES_VERBOSE is true)
    debug_log() {
        local message="$1"
        local current_time=$(date +%s.%N)
        local elapsed=$(echo "$current_time - $__STARTUP_PROFILE_START" | bc -l 2>/dev/null || echo "0")
        [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "🐛 [${elapsed}s] $message"
    }
    
    # Function to log detailed timing for specific operations
    profile_detail() {
        local operation="$1"
        local start_time="$2"
        local end_time="$3"
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        __STARTUP_PROFILE_DETAILED+=("${duration}s: $operation")
        [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "🔍 ${duration}s: $operation"
    }
    
    # Function to show final detailed profile
    profile_summary() {
        echo "🚀 Detailed Startup Profile Summary:"
        echo "===================================="
        for time_entry in "${__STARTUP_PROFILE_TIMES[@]}"; do
            echo "  $time_entry"
        done
        
        echo ""
        echo "🔍 Detailed Operation Times:"
        echo "----------------------------"
        for detail_entry in "${__STARTUP_PROFILE_DETAILED[@]}"; do
            echo "  $detail_entry"
        done
        
        local total_time=$(echo "$(date +%s.%N) - $__STARTUP_PROFILE_START" | bc -l 2>/dev/null || echo "0")
        echo ""
        echo "📊 Total startup time: ${total_time}s"
        
        # Identify slowest operations
        echo ""
        echo "🐌 Slowest Operations (>0.1s):"
        echo "-------------------------------"
        for detail_entry in "${__STARTUP_PROFILE_DETAILED[@]}"; do
            local duration=$(echo "$detail_entry" | cut -d's' -f1)
            if (( $(echo "$duration > 0.1" | bc -l 2>/dev/null || echo 0) )); then
                echo "  $detail_entry"
            fi
        done
    }
    
    # Hook to show summary on shell exit
    profile_log "Shell startup began"
else
    # No-op functions when profiling is disabled
    profile_log() { : }
    profile_detail() { : }
    profile_summary() { : }
    debug_log() { : }
fi
