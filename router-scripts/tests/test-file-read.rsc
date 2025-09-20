# Test File Reading Script for RouterOS v7
:local fileName "adblock-diff.txt"

:log info "=== Testing File Reading ==="

# Check if file exists
:if ([:len [/file find name=$fileName]] > 0) do={
    :log info ("File '" . $fileName . "' exists")
    
    # Get file properties - RouterOS v7 syntax
    :local fileId [/file find name=$fileName]
    :local fileSize [/file get $fileId size]
    :local fileCreationTime [/file get $fileId creation-time]
    :log info ("File size: " . $fileSize . " bytes")
    :log info ("Creation time: " . $fileCreationTime)
    
    # Test different ways to read the file
    :log info "Testing file content reading..."
    
    :do {
        :local fileContent [/file get $fileId contents]
        :local contentLength [:len $fileContent]
        :log info ("Content length: " . $contentLength . " characters")
        
        :if ($contentLength > 0) do={
            # Show first 100 characters
            :local sample ""
            :if ($contentLength > 100) do={
                :set sample [:pick $fileContent 0 100]
            } else={
                :set sample $fileContent
            }
            :log info ("First 100 chars: '" . $sample . "'")
            
            # Check for different line ending types
            :local crlfPos [:find $fileContent "\r\n"]
            :local lfPos [:find $fileContent "\n"]
            :local crPos [:find $fileContent "\r"]
            
            :log info ("CRLF found at position: " . $crlfPos)
            :log info ("LF found at position: " . $lfPos)
            :log info ("CR found at position: " . $crPos)
            
            # Try to parse first few lines manually
            :local pos 0
            :local lineCount 0
            :while ($pos < $contentLength && $lineCount < 5) do={
                :local nextCRLF [:find $fileContent "\r\n" $pos]
                :local nextLF [:find $fileContent "\n" $pos]
                :local nextCR [:find $fileContent "\r" $pos]
                
                :local nextPos $contentLength
                :local lineEnding "EOF"
                
                # Find the earliest line ending
                :if ($nextCRLF != -1 && $nextCRLF < $nextPos) do={
                    :set nextPos $nextCRLF
                    :set lineEnding "CRLF"
                }
                :if ($nextLF != -1 && $nextLF < $nextPos) do={
                    :set nextPos $nextLF
                    :set lineEnding "LF"
                }
                :if ($nextCR != -1 && $nextCR < $nextPos) do={
                    :set nextPos $nextCR
                    :set lineEnding "CR"
                }
                
                :local line [:pick $fileContent $pos $nextPos]
                :if ([:len $line] > 0) do={
                    :set lineCount ($lineCount + 1)
                    :log info ("Line " . $lineCount . " (" . $lineEnding . "): '" . $line . "'")
                }
                
                # Move past the line ending
                :if ($lineEnding = "CRLF") do={ :set pos ($nextPos + 2) }
                :if ($lineEnding = "LF") do={ :set pos ($nextPos + 1) }
                :if ($lineEnding = "CR") do={ :set pos ($nextPos + 1) }
                :if ($lineEnding = "EOF") do={ :set pos $contentLength }
            }
            
        } else={
            :log warning "File content is empty!"
        }
        
    } on-error={
        :log error "Failed to read file content!"
    }
    
} else={
    :log error ("File '" . $fileName . "' not found!")
    
    # List all files to see what's available
    :log info "Available files:"
    :foreach file in=[/file find] do={
        :local name [/file get $file name]
        :local size [/file get $file size]
        :log info ("  " . $name . " (" . $size . " bytes)")
    }
}

:log info "=== File Reading Test Complete ==="