# AdBlock FULL Import Script for RouterOS v7 (RB760iGS)
# This script downloads the complete blocklist (all domains)
# WARNING: This may take longer and use more memory than the incremental script
:local adList "adblock-list"

# Use the full clean file for complete blocklist
:local fileName "adblock-clean.txt"
:local fileUrl "https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-clean.txt"

:log info "=== AdBlock FULL Import Started ==="
:log info "Script version: 2.1 (Full list import)"

# First, validate current setup
:local totalLists [:len [/ip firewall address-list find]]
:log info ("Total address list entries in system: " . $totalLists)

# Check if our address list exists
:local existingInList [:len [/ip firewall address-list find list=$adList]]
:log info ("Entries in '" . $adList . "' list: " . $existingInList)

# WARNING: Full import - clear existing list first
:if ($existingInList > 0) do={
    :log info "WARNING: Clearing existing address list for full import..."
    :foreach item in=[/ip firewall address-list find list=$adList] do={
        /ip firewall address-list remove $item
    }
    :log info "Existing entries cleared"
}

# Check if we can access the internet
:log info ("AdBlock: Downloading " . $fileUrl)

# Remove existing file if it exists
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
    :log info "AdBlock: Removed existing file"
}

:do {
    /tool fetch url=$fileUrl dst-path=$fileName
    :log info "AdBlock: File download completed"
    
    # Wait a moment for file system to sync
    :delay 2
    
    # Check if file exists after download
    :if ([:len [/file find name=$fileName]] = 0) do={
        :log error "AdBlock: Downloaded file not found after fetch"
        :error "File not found after download"
    }
    
    :local fileId [/file find name=$fileName]
    :local fileSize [/file get $fileId size]
    :log info ("AdBlock: Downloaded file size: " . $fileSize . " bytes")
    
    :if ($fileSize = 0) do={
        :log error "AdBlock: Downloaded file is empty"
        :error "No valid blocklist data available"
    }
    
} on-error={
    :log error "AdBlock: Failed to download file - check internet connection and URL"
    :error "Download failed"
}

:log info ("AdBlock: Importing FULL list from " . $fileName)

# Read file into array and show sample content
:do {
    :local fileId [/file find name=$fileName]
    :local fileContent [/file get $fileId contents]
    :local start 0
    :local end 0
    :local len [:len $fileContent]
    :local processedDomains 0
    :local addedDomains 0

    :log info ("AdBlock: Processing file content (" . $len . " characters)")

    :if ($len = 0) do={
        :log error "AdBlock: File content is empty - cannot proceed"
        :error "Empty file content"
    }

    # Show first 50 characters for debugging
    :local sample ""
    :if ($len > 50) do={
        :set sample [:pick $fileContent 0 50]
    } else={
        :set sample $fileContent
    }
    :log info ("AdBlock: File sample: '" . $sample . "'")

    # Detect line ending type
    :local crlfPos [:find $fileContent "\r\n"]
    :local lfPos [:find $fileContent "\n"]
    :local lineEnding "\n"
    :local lineEndingName "LF"
    
    :if ($crlfPos != -1 && ($lfPos = -1 || $crlfPos < $lfPos)) do={
        :set lineEnding "\r\n"
        :set lineEndingName "CRLF"
    }
    :log info ("AdBlock: Detected line ending: " . $lineEndingName)

    # Count lines in file first
    :local lineCount 0
    :local pos 0
    :while ($pos < $len) do={
        :local nextPos [:find $fileContent $lineEnding $pos]
        :if ($nextPos = -1) do={ :set nextPos $len }
        :local line [:pick $fileContent $pos $nextPos]
        # Clean line (remove any remaining CR or LF)
        :if ([:find $line "\r"] >= 0) do={
            :set line [:pick $line 0 [:find $line "\r"]]
        }
        :if ([:find $line "\n"] >= 0) do={
            :set line [:pick $line 0 [:find $line "\n"]]
        }
        :if ([:len $line] > 0) do={ :set lineCount ($lineCount + 1) }
        :set pos ($nextPos + [:len $lineEnding])
    }
    :log info ("AdBlock: Found " . $lineCount . " non-empty lines in file")

    # Process file line by line
    :set start 0
    :while ($start < $len) do={
        :local end [:find $fileContent $lineEnding $start]
        :if ($end = -1) do={ :set end $len }
        :local domain [:pick $fileContent $start $end]
        
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
            :set processedDomains ($processedDomains + 1)
            
            # Log first few domains for debugging
            :if ($processedDomains <= 3) do={
                :log info ("AdBlock: Processing domain #" . $processedDomains . ": '" . $domain . "' (length: " . [:len $domain] . ")")
            }
            
            :do {
                /ip firewall address-list add list=$adList address=$domain disabled=no
                :set addedDomains ($addedDomains + 1)
                :if ($addedDomains <= 3) do={
                    :log info ("AdBlock: Added domain: '" . $domain . "'")
                }
            } on-error={
                :log warning ("AdBlock: Failed to add domain: '" . $domain . "'")
            }
            
            # Log progress every 500 domains for full import
            :if (($processedDomains % 500) = 0) do={
                :log info ("AdBlock: Processed " . $processedDomains . " domains...")
            }
        }
        :set start ($end + [:len $lineEnding])
    }

} on-error={
    :log error "AdBlock: Failed to read or process file content"
    :error "File processing failed"
}

:log info ("AdBlock: Processed " . $processedDomains . " domains total")
:log info ("AdBlock: Added " . $addedDomains . " new domains")

# Final count
:local finalCount [:len [/ip firewall address-list find list=$adList]]
:log info ("AdBlock: Final count: " . $finalCount . " active entries")

:log info "AdBlock: FULL import completed successfully!"