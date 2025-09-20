# AdBlock Import Script for RouterOS v7 (RB760iGS) - Chunked Version with State Tracking
# This script downloads and processes multiple small chunk files to avoid memory limitations
# Each chunk contains up to 500 domains, making it compatible with RouterOS memory constraints
# Saves state to only process new chunks on subsequent runs (incremental updates)
:local adList "adblock-list"
:local stateFile "adblock-state.txt"

# GitHub base URL for chunk files
:local baseUrl "https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/"
:local controlFile "adblock-chunks-count.txt"

:log info "=== AdBlock Chunked Script Started ==="
:log info "Script version: 3.1 (chunked with incremental state tracking)"

# First, validate current setup
:local totalLists [:len [/ip firewall address-list find]]
:log info ("Total address list entries in system: " . $totalLists)

# Check if our address list exists
:local existingInList [:len [/ip firewall address-list find list=$adList]]
:log info ("Entries in '" . $adList . "' list: " . $existingInList)

# Read last processed chunk count from state file (if exists)
:local lastProcessedChunks 0
:if ([:len [/file find name=$stateFile]] > 0) do={
    :do {
        :local stateContent [/file get [/file find name=$stateFile] contents]
        :if ([:len $stateContent] > 0) do={
            # Parse last chunk count (remove any line endings)
            :local lastChunkStr $stateContent
            :if ([:find $lastChunkStr "\r"] >= 0) do={
                :set lastChunkStr [:pick $lastChunkStr 0 [:find $lastChunkStr "\r"]]
            }
            :if ([:find $lastChunkStr "\n"] >= 0) do={
                :set lastChunkStr [:pick $lastChunkStr 0 [:find $lastChunkStr "\n"]]
            }
            :set lastProcessedChunks [:tonum $lastChunkStr]
            :log info ("AdBlock: Last processed chunks: " . $lastProcessedChunks)
        }
    } on-error={
        :log warning "AdBlock: Could not read state file, treating as first run"
        :set lastProcessedChunks 0
    }
} else={
    :log info "AdBlock: No state file found, treating as first run"
}

# List first few existing entries for debugging
:if ($existingInList > 0) do={
    :log info "First few existing entries:"
    :local count 0
    :foreach item in=[/ip firewall address-list find list=$adList] do={
        :if ($count < 3) do={
            :local address [/ip firewall address-list get $item address]
            :local disabled [/ip firewall address-list get $item disabled]
            :log info ("  Entry " . ($count + 1) . ": " . $address . " (disabled: " . $disabled . ")")
            :set count ($count + 1)
        }
    }
}

# Download control file to get chunk count
:log info ("AdBlock: Downloading control file: " . $controlFile)

# Remove existing control file if it exists
:if ([:len [/file find name=$controlFile]] > 0) do={
    /file remove $controlFile
    :log info "AdBlock: Removed existing control file"
}

:local chunkCount 0
:do {
    /tool fetch url=($baseUrl . $controlFile) dst-path=$controlFile
    :log info "AdBlock: Control file download completed"
    
    # Wait for file system to sync
    :delay 2
    
    # Check if control file exists after download
    :if ([:len [/file find name=$controlFile]] = 0) do={
        :log error "AdBlock: Control file not found after fetch"
        :error "Control file not found after download"
    }
    
    :local controlFileId [/file find name=$controlFile]
    :local controlFileSize [/file get $controlFileId size]
    :log info ("AdBlock: Control file size: " . $controlFileSize . " bytes")
    
    # Read chunk count from control file
    :local controlContent [/file get $controlFileId contents]
    :local controlLen [:len $controlContent]
    
    :if ($controlLen = 0) do={
        :log error "AdBlock: Control file is empty"
        :error "Empty control file"
    }
    
    # Parse chunk count (remove any line endings)
    :local chunkCountStr $controlContent
    :if ([:find $chunkCountStr "\r"] >= 0) do={
        :set chunkCountStr [:pick $chunkCountStr 0 [:find $chunkCountStr "\r"]]
    }
    :if ([:find $chunkCountStr "\n"] >= 0) do={
        :set chunkCountStr [:pick $chunkCountStr 0 [:find $chunkCountStr "\n"]]
    }
    
    :set chunkCount [:tonum $chunkCountStr]
    :log info ("AdBlock: Found " . $chunkCount . " chunks to process")
    
} on-error={
    :log error "AdBlock: Failed to download or read control file"
    :error "Control file download failed"
}

# Validate chunk count
:if ($chunkCount <= 0) do={
    :log error "AdBlock: Invalid chunk count"
    :error "Invalid chunk count"
}

# Determine processing strategy
:local startChunk 1
:local processingMode "full"
:if ($lastProcessedChunks > 0 && $chunkCount >= $lastProcessedChunks) do={
    :if ($chunkCount = $lastProcessedChunks) do={
        :log info "AdBlock: No new chunks available, already up to date"
        :error "Already up to date"
    } else={
        :set startChunk ($lastProcessedChunks + 1)
        :set processingMode "incremental"
        :log info ("AdBlock: Incremental update - processing chunks " . $startChunk . " to " . $chunkCount)
    }
} else={
    :if ($lastProcessedChunks > 0) do={
        :log warning ("AdBlock: Chunk count decreased from " . $lastProcessedChunks . " to " . $chunkCount . ", doing full refresh")
    }
    :log info ("AdBlock: Full processing - processing all " . $chunkCount . " chunks")
}

# Count existing entries before processing
:local existingCount [:len [/ip firewall address-list find list=$adList]]
:log info ("AdBlock: Found " . $existingCount . " existing entries")

# Disable all existing entries only for full processing
:local disabledCount 0
:if ($processingMode = "full") do={
    :foreach i in=[/ip firewall address-list find list=$adList] do={
        /ip firewall address-list set $i disabled=yes
        :set disabledCount ($disabledCount + 1)
    }
    :log info ("AdBlock: Disabled " . $disabledCount . " existing entries (full refresh)")
} else={
    :log info ("AdBlock: Incremental mode - keeping existing entries enabled")
}

# Process chunk files (either all chunks or just new ones)
:local totalProcessedDomains 0
:local totalEnabledDomains 0
:local totalAddedDomains 0

:for chunkNum from=$startChunk to=$chunkCount do={
    :local chunkFileName ("adblock-chunk-" . $chunkNum . ".txt")
    :local chunkUrl ($baseUrl . $chunkFileName)
    
    :log info ("AdBlock: Processing chunk " . $chunkNum . "/" . $chunkCount . ": " . $chunkFileName)
    
    # Remove existing chunk file if it exists
    :if ([:len [/file find name=$chunkFileName]] > 0) do={
        /file remove $chunkFileName
    }
    
    :do {
        /tool fetch url=$chunkUrl dst-path=$chunkFileName
        :delay 1
        
        # Check if chunk file exists after download
        :if ([:len [/file find name=$chunkFileName]] = 0) do={
            :log warning ("AdBlock: Chunk file " . $chunkNum . " not found after fetch, skipping")
        } else={
            :local chunkFileId [/file find name=$chunkFileName]
            :local chunkFileSize [/file get $chunkFileId size]
            :log info ("AdBlock: Chunk " . $chunkNum . " size: " . $chunkFileSize . " bytes")
            
            # Read and process chunk file
            :local chunkContent [/file get $chunkFileId contents]
            :local chunkLen [:len $chunkContent]
            
            :if ($chunkLen > 0) do={
                :log info ("AdBlock: Chunk " . $chunkNum . " content read: " . $chunkLen . " characters")
                
                # Process chunk content line by line
                :local chunkProcessed 0
                :local chunkEnabled 0
                :local chunkAdded 0
                
                # Detect line ending type
                :local crlfPos [:find $chunkContent "\r\n"]
                :local lfPos [:find $chunkContent "\n"]
                :local lineEnding "\n"
                
                :if ($crlfPos != -1 && ($lfPos = -1 || $crlfPos < $lfPos)) do={
                    :set lineEnding "\r\n"
                }
                
                # Process file line by line
                :local start 0
                :while ($start < $chunkLen) do={
                    :local end [:find $chunkContent $lineEnding $start]
                    :if ($end = -1) do={ :set end $chunkLen }
                    :local domain [:pick $chunkContent $start $end]
                    
                    # Clean up domain (remove any carriage returns and whitespace)
                    :set domain [:tostr $domain]
                    :if ([:find $domain "\r"] >= 0) do={
                        :set domain [:pick $domain 0 [:find $domain "\r"]]
                    }
                    :if ([:find $domain "\n"] >= 0) do={
                        :set domain [:pick $domain 0 [:find $domain "\n"]]
                    }
                    
                    # Trim whitespace from domain
                    :while ([:len $domain] > 0 && ([:pick $domain 0 1] = " " || [:pick $domain 0 1] = "\t")) do={
                        :set domain [:pick $domain 1 [:len $domain]]
                    }
                    :while ([:len $domain] > 0 && ([:pick $domain ([:len $domain] - 1) [:len $domain]] = " " || [:pick $domain ([:len $domain] - 1) [:len $domain]] = "\t")) do={
                        :set domain [:pick $domain 0 ([:len $domain] - 1)]
                    }
                    
                    :if ([:len $domain] > 0) do={
                        :set chunkProcessed ($chunkProcessed + 1)
                        
                        # Log first domain of first chunk for debugging
                        :if ($chunkNum = 1 && $chunkProcessed = 1) do={
                            :log info ("AdBlock: First domain: '" . $domain . "' (length: " . [:len $domain] . ")")
                        }
                        
                        :local found false
                        :if ($processingMode = "full") do={
                            # Full mode: check if domain exists and re-enable it
                            :foreach item in=[/ip firewall address-list find list=$adList] do={
                                :if ([/ip firewall address-list get $item address] = $domain) do={
                                    /ip firewall address-list set $item disabled=no
                                    :set found true
                                    :set chunkEnabled ($chunkEnabled + 1)
                                }
                            }
                        } else={
                            # Incremental mode: check if domain already exists
                            :foreach item in=[/ip firewall address-list find list=$adList] do={
                                :if ([/ip firewall address-list get $item address] = $domain) do={
                                    :set found true
                                }
                            }
                        }
                        :if ($found = false) do={
                            :do {
                                /ip firewall address-list add list=$adList address=$domain disabled=no
                                :set chunkAdded ($chunkAdded + 1)
                            } on-error={
                                :log warning ("AdBlock: Failed to add domain: '" . $domain . "'")
                            }
                        }
                    }
                    :set start ($end + [:len $lineEnding])
                }
                
                :log info ("AdBlock: Chunk " . $chunkNum . " processed " . $chunkProcessed . " domains (enabled: " . $chunkEnabled . ", added: " . $chunkAdded . ")")
                
                :set totalProcessedDomains ($totalProcessedDomains + $chunkProcessed)
                :set totalEnabledDomains ($totalEnabledDomains + $chunkEnabled)
                :set totalAddedDomains ($totalAddedDomains + $chunkAdded)
                
            } else={
                :log warning ("AdBlock: Chunk " . $chunkNum . " content is empty")
            }
            
            # Clean up chunk file to save space
            /file remove $chunkFileName
        }
        
    } on-error={
        :log warning ("AdBlock: Failed to download chunk " . $chunkNum . ", skipping")
    }
    
    # Small delay between chunks to avoid overwhelming the system
    :delay 1
}

:log info ("AdBlock: All chunks processed")
:log info ("AdBlock: Total processed " . $totalProcessedDomains . " domains")
:log info ("AdBlock: Total enabled " . $totalEnabledDomains . " existing domains")
:log info ("AdBlock: Total added " . $totalAddedDomains . " new domains")

# Remove disabled entries only in full mode (no longer in blocklist)
:local removedCount 0
:if ($processingMode = "full") do={
    :foreach i in=[/ip firewall address-list find list=$adList disabled=yes] do={
        /ip firewall address-list remove $i
        :set removedCount ($removedCount + 1)
    }
    :log info ("AdBlock: Removed " . $removedCount . " obsolete entries")
} else={
    :log info ("AdBlock: Incremental mode - no entries removed")
}

# Update state file with current chunk count
:do {
    # Remove existing state file
    :if ([:len [/file find name=$stateFile]] > 0) do={
        /file remove $stateFile
    }
    # Create new state file with current chunk count
    /file print file=$stateFile where name=$stateFile
    :delay 1
    /file set [/file find name=$stateFile] contents=[:tostr $chunkCount]
    :log info ("AdBlock: Updated state file - processed " . $chunkCount . " chunks")
} on-error={
    :log warning "AdBlock: Could not update state file"
}

# Clean up control file
:if ([:len [/file find name=$controlFile]] > 0) do={
    /file remove $controlFile
}

# Final count
:local finalCount [:len [/ip firewall address-list find list=$adList]]
:log info ("AdBlock: Final count: " . $finalCount . " active entries")

:log info ("AdBlock: " . $processingMode . " import completed successfully!")