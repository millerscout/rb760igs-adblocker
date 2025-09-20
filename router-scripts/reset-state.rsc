# AdBlock State Reset Script
# This script resets the state file to force a full refresh on the next run
:local stateFile "adblock-state.txt"

:log info "=== AdBlock State Reset ==="

# Remove state file if it exists
:if ([:len [/file find name=$stateFile]] > 0) do={
    /file remove $stateFile
    :log info "AdBlock: State file removed - next run will do full refresh"
} else={
    :log info "AdBlock: No state file found - already reset"
}

:log info "AdBlock: State reset completed"