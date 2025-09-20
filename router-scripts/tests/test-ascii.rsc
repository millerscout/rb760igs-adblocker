# Test ASCII File Reading for RouterOS v7
:local fileName "adblock-clean.txt"

:log info "=== Testing ASCII File ==="

# Test download first
:log info "Testing download..."
:do {
    /tool fetch url="https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-clean.txt" dst-path=$fileName
    :delay 2
    
    :if ([:len [/file find name=$fileName]] > 0) do={
        :local fileList [/file find name=$fileName]
        :local fileId [:pick $fileList 0]
        :local fileSize [/file get $fileId size]
        :log info ("Downloaded file size: " . $fileSize . " bytes")
        
        :if ($fileSize > 0) do={
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
                :log info "SUCCESS: ASCII file can be read properly!"
            } else={
                :log error "Content is still empty with ASCII file"
            }
        } else={
            :log error "Downloaded ASCII file is empty"
        }
    } else={
        :log error "ASCII file not found after download"
    }
} on-error={
    :log error "Failed to download ASCII file"
}

:log info "=== ASCII Test Complete ==="