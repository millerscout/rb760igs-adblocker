# Combined Download + Read Test (based on working test-file-read.rsc)
:local fileName "adblock-test-download.txt"

:log info "=== Combined Download + Read Test ==="

# Remove any existing file first
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
    :log info "Removed existing file"
    :delay 1
}

# Download the file
:log info "Downloading file..."
:do {
    /tool fetch url="https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-diff.txt" dst-path=$fileName
    :log info "Download command completed"
    :delay 3
} on-error={
    :log error "Download failed"
    :error "Cannot proceed without file"
}

# Now use the WORKING approach from test-file-read.rsc
:log info "Testing file reading using working method..."

# Check if file exists
:if ([:len [/file find name=$fileName]] > 0) do={
    :log info ("File '" . $fileName . "' exists after download")
    
    # Get file properties - RouterOS v7 syntax (same as working script)
    :local fileId [/file find name=$fileName]
    :local fileSize [/file get $fileId size]
    :local fileCreationTime [/file get $fileId creation-time]
    :log info ("File size: " . $fileSize . " bytes")
    :log info ("Creation time: " . $fileCreationTime)
    
    # Test content reading using EXACT same method as working script
    :log info "Testing file content reading..."
    
    :do {
        :local fileContent [/file get $fileId contents]
        :local contentLength [:len $fileContent]
        :log info ("Content length: " . $contentLength . " characters")
        
        :if ($contentLength > 0) do={
            # Show first 100 characters (same as working script)
            :local sample ""
            :if ($contentLength > 100) do={
                :set sample [:pick $fileContent 0 100]
            } else={
                :set sample $fileContent
            }
            :log info ("First 100 chars: '" . $sample . "'")
            
            # Check for different line ending types (same as working script)
            :local crlfPos [:find $fileContent "\r\n"]
            :local lfPos [:find $fileContent "\n"]
            :local crPos [:find $fileContent "\r"]
            
            :log info ("CRLF found at position: " . $crlfPos)
            :log info ("LF found at position: " . $lfPos)
            :log info ("CR found at position: " . $crPos)
            
            # Parse first few lines (same as working script)
            :local pos 0
            :local lineCount 0
            :while ($pos < $contentLength && $lineCount < 3) do={
                :local nextLF [:find $fileContent "\n" $pos]
                
                :local nextPos $contentLength
                :if ($nextLF != -1) do={
                    :set nextPos $nextLF
                }
                
                :local line [:pick $fileContent $pos $nextPos]
                :if ([:len $line] > 0) do={
                    :set lineCount ($lineCount + 1)
                    :log info ("Line " . $lineCount . ": '" . $line . "'")
                }
                
                :set pos ($nextPos + 1)
            }
            
            :log info "SUCCESS: Downloaded file can be read properly!"
            
        } else={
            :log error "File content is empty despite download!"
        }
        
    } on-error={
        :log error "Failed to read downloaded file content!"
    }
    
} else={
    :log error ("File '" . $fileName . "' not found after download!")
}

:log info "=== Combined Test Complete ==="