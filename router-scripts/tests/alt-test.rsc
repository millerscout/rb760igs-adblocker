# Alternative File Reading for RouterOS v7
:local fileName "adblock-diff.txt"

:log info "=== Alternative File Reading Test ==="

# Check if file exists
:if ([:len [/file find name=$fileName]] > 0) do={
    :log info ("File '" . $fileName . "' found")
    
    # In RouterOS v7, file reading might need different approach
    :do {
        # Method 1: Try to get file info first
        :local fileList [/file find name=$fileName]
        :if ([:len $fileList] > 0) do={
            :local fileId [:pick $fileList 0]
            :log info ("File ID: " . [:tostr $fileId])
            
            # Get basic file properties
            :local fileName2 [/file get $fileId name]
            :local fileSize [/file get $fileId size]
            :log info ("File name: " . $fileName2)
            :log info ("File size: " . $fileSize . " bytes")
            
            # Try to read contents - this might not work in all RouterOS v7 versions
            :do {
                :local content [/file get $fileId contents]
                :log info ("Content successfully read: " . [:len $content] . " characters")
                
                # Show first few characters
                :if ([:len $content] > 50) do={
                    :local sample [:pick $content 0 50]
                    :log info ("First 50 chars: '" . $sample . "'")
                }
            } on-error={
                :log warning "Cannot read file contents - 'contents' property not available"
                :log info "This RouterOS version might not support direct file content reading"
                :log info "You may need to use /import or other methods"
            }
        }
    } on-error={
        :log error "Failed to access file properties"
    }
    
} else={
    :log error ("File '" . $fileName . "' not found")
    
    # Show available files
    :log info "Available files:"
    :foreach f in=[/file find] do={
        :local n [/file get $f name]
        :local s [/file get $f size]
        :log info ("  " . $n . " (" . $s . " bytes)")
    }
}

:log info "=== Alternative Test Complete ==="