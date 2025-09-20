# Test ASCII File Reading for RouterOS v7
:local fileName "adblock-clean.txt"

:log info "=== Testing ASCII File ==="

# Remove any existing file first
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
    :log info "Removed existing file"
    :delay 1
}

# Test download first
:log info "Testing download..."
:do {
    /tool fetch url="https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-clean.txt" dst-path=$fileName
    :log info "Download command completed"
    :delay 3
    
    :if ([:len [/file find name=$fileName]] > 0) do={
        :local fileList [/file find name=$fileName]
        :local fileId [:pick $fileList 0]
        :local fileSize [/file get $fileId size]
        :log info ("Downloaded file size: " . $fileSize . " bytes")
        
        :if ($fileSize > 0) do={
            :log info "Attempting to read file content..."
            :local content [/file get $fileId contents]
            :local contentLength [:len $content]
            :log info ("Content length: " . $contentLength . " characters")
            
            :if ($contentLength > 0) do={
                # Show first line
                :local firstNewline [:find $content "\n"]
                :if ($firstNewline > 0) do={
                    :local firstLine [:pick $content 0 $firstNewline]
                    :log info ("First line: '" . $firstLine . "'")
                } else={
                    :local sample [:pick $content 0 50]
                    :log info ("First 50 chars: '" . $sample . "'")
                }
                
                # Check for carriage returns
                :local crCount 0
                :local pos 0
                :while ($pos < $contentLength && $crCount < 10) do={
                    :if ([:pick $content $pos ($pos + 1)] = "\r") do={
                        :set crCount ($crCount + 1)
                        :log info ("Found carriage return at position: " . $pos)
                    }
                    :set pos ($pos + 1)
                }
                :log info ("Total carriage returns found in first check: " . $crCount)
                
                :log info "SUCCESS: ASCII file can be read properly!"
            } else={
                :log error "Content is still empty with ASCII file"
                # Try to get file details another way
                :log info "File details from /file print:"
                /file print where name=$fileName
            }
        } else={
            :log error "Downloaded ASCII file is empty"
            :log info "File system details:"
            /file print where name=$fileName
        }
    } else={
        :log error "ASCII file not found after download"
        :log info "All files in system:"
        /file print
    }
} on-error={
    :log error "Failed to download ASCII file"
    :log info "Network/download error occurred"
}

:log info "=== ASCII Test Complete ==="