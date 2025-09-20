# Test diff file download for RouterOS v7
:local fileName "adblock-diff-test.txt"

:log info "=== Testing Diff File Download ==="

# Remove any existing file first
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
    :log info "Removed existing file"
    :delay 1
}

:log info "Testing diff file download..."
:do {
    /tool fetch url="https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-diff.txt" dst-path=$fileName
    :log info "Download command completed"
    :delay 3
    
    :if ([:len [/file find name=$fileName]] > 0) do={
        :local fileList [/file find name=$fileName]
        :local fileId [:pick $fileList 0]
        :local fileSize [/file get $fileId size]
        :log info ("Downloaded diff file size: " . $fileSize . " bytes")
        
        :if ($fileSize > 0) do={
            :log info "Attempting to read diff file content..."
            :local content [/file get $fileId contents]
            :local contentLength [:len $content]
            :log info ("Diff content length: " . $contentLength . " characters")
            
            :if ($contentLength > 0) do={
                # Show first few lines
                :local pos 0
                :local lineCount 0
                :local maxLines 3
                
                :while ($pos < $contentLength && $lineCount < $maxLines) do={
                    :local nextPos [:find $content "\n" $pos]
                    :if ($nextPos = -1) do={ :set nextPos $contentLength }
                    :local line [:pick $content $pos $nextPos]
                    :log info ("Line " . ($lineCount + 1) . ": '" . $line . "'")
                    :set lineCount ($lineCount + 1)
                    :set pos ($nextPos + 1)
                }
                
                :log info "SUCCESS: Diff file can be read properly!"
            } else={
                :log error "Diff content is empty"
                :log info "File details:"
                /file print where name=$fileName
            }
        } else={
            :log error "Downloaded diff file is empty"
        }
    } else={
        :log error "Diff file not found after download"
    }
} on-error={
    :log error ("Failed to download diff file: " . [:tostr $@])
}

:log info "=== Diff Test Complete ==="