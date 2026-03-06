#!/bin/bash

# Get actual RAM usage using vm_stat
vm_stat_output=$(vm_stat)
pages_free=$(echo "$vm_stat_output" | grep "Pages free:" | awk '{print $3}' | sed 's/\.//')
pages_active=$(echo "$vm_stat_output" | grep "Pages active:" | awk '{print $3}' | sed 's/\.//')
pages_inactive=$(echo "$vm_stat_output" | grep "Pages inactive:" | awk '{print $3}' | sed 's/\.//')
pages_speculative=$(echo "$vm_stat_output" | grep "Pages speculative:" | awk '{print $3}' | sed 's/\.//')
pages_wired=$(echo "$vm_stat_output" | grep "Pages wired down:" | awk '{print $4}' | sed 's/\.//')

# Calculate actual memory usage percentage (only count active + wired as truly "used")
total_pages=$((pages_free + pages_active + pages_inactive + pages_speculative + pages_wired))
used_pages=$((pages_active + pages_wired))
raw=$(echo "scale=2; ($used_pages * 100) / $total_pages" | bc -l)

normalized=$(echo "$raw / 100" | bc -l)
percent=$(printf "%.0f%%" "$raw")

sketchybar --set ram_usage label="$percent"
sketchybar --push ram_usage "$normalized"
