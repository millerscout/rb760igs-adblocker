# Test Download Script for RouterOS v7
:local fileName "test-download.txt"
:local fileUrl "https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-diff.txt"

:log info "=== Testing File Download ==="

# Clean up any existing test file
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
}

:log info ("Testing download from: " . $fileUrl)

:do {
    /tool fetch url=$fileUrl dst-path=$fileName
    :log info "Download completed"
    
    # Wait for file system
    :delay 2
    
    # Check file
    :if ([:len [/file find name=$fileName]] > 0) do={
        :local fileSize [/file get $fileName size]
        :log info ("File size: " . $fileSize . " bytes")
        
        :if ($fileSize > 0) do={
            # Show first few lines
            :local fileContent [/file get $fileName contents]
            :local firstNewline [:find $fileContent "\n"]
            :if ($firstNewline > 0) do={
                :local firstLine [:pick $fileContent 0 $firstNewline]
                :log info ("First line: '" . $firstLine . "'")
            }
        } else={
            :log warning "File is empty!"
        }
    } else={
        :log error "File not found after download!"
    }
    
} on-error={
    :log error "Download failed!"
}

# Test alternative file
:log info "Testing alternative file..."
:local altUrl "https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-clean.txt"
:local altFileName "test-alt.txt"

:do {
    /tool fetch url=$altUrl dst-path=$altFileName
    :delay 2
    
    :if ([:len [/file find name=$altFileName]] > 0) do={
        :local altSize [/file get $altFileName size]
        :log info ("Alternative file size: " . $altSize . " bytes")
    }
} on-error={
    :log error "Alternative download failed!"
}

:log info "=== Test Complete ==="