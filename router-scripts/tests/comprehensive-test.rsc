# Comprehensive RouterOS File Reading Test
:local fileName "test-simple.txt"

:log info "=== Comprehensive File Test ==="

# Remove any existing file first
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
    :delay 1
}

# Test 1: Try a very simple small file first
:log info "Test 1: Downloading simple test file..."
:do {
    /tool fetch url="https://httpbin.org/robots.txt" dst-path=$fileName
    :log info "Simple download completed"
    :delay 2
    
    :if ([:len [/file find name=$fileName]] > 0) do={
        :local fileList [/file find name=$fileName]
        :local fileId [:pick $fileList 0]
        :local fileSize [/file get $fileId size]
        :log info ("Simple file size: " . $fileSize . " bytes")
        
        :if ($fileSize > 0) do={
            :local content [/file get $fileId contents]
            :local contentLength [:len $content]
            :log info ("Simple content length: " . $contentLength . " characters")
            
            :if ($contentLength > 0) do={
                :log info ("First 100 chars: '" . [:pick $content 0 100] . "'")
                :log info "SUCCESS: Simple file reading works!"
            } else={
                :log error "Simple file content is empty despite size > 0"
            }
        }
    }
} on-error={
    :log error "Failed to download simple test file"
}

# Clean up
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
    :delay 1
}

# Test 2: Try our adblock file with different approach
:set fileName "adblock-test.txt"
:log info "Test 2: Downloading our adblock file..."
:do {
    /tool fetch url="https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-diff.txt" dst-path=$fileName
    :log info "Adblock download completed"
    :delay 3
    
    :if ([:len [/file find name=$fileName]] > 0) do={
        :local fileList [/file find name=$fileName]
        :local fileId [:pick $fileList 0]
        :local fileSize [/file get $fileId size]
        :log info ("Adblock file size: " . $fileSize . " bytes")
        
        # Show file details
        :log info "File details:"
        /file print detail where name=$fileName
        
        :if ($fileSize > 0) do={
            :log info "Attempting to read adblock file..."
            
            # Try reading with error handling
            :do {
                :local content [/file get $fileId contents]
                :local contentLength [:len $content]
                :log info ("Adblock content length: " . $contentLength . " characters")
                
                :if ($contentLength > 0) do={
                    :log info "SUCCESS: Adblock file can be read!"
                    :log info ("First domain: '" . [:pick $content 0 50] . "'")
                } else={
                    :log error "Adblock content is empty despite file size"
                }
            } on-error={
                :log error "Error reading adblock file contents"
            }
        }
    } else={
        :log error "Adblock file not found after download"
    }
} on-error={
    :log error "Failed to download adblock file"
}

# Test 3: Check RouterOS version and capabilities
:log info "Test 3: RouterOS system info..."
:log info ("RouterOS version: " . [/system resource get version])
:log info ("Architecture: " . [/system resource get architecture-name])

:log info "=== Comprehensive Test Complete ==="