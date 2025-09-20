# Simple File Test for RouterOS v7
:local fileName "adblock-diff.txt"

:log info "=== Simple File Test ==="

# Method 1: Check if file exists
:local fileCount [:len [/file find name=$fileName]]
:log info ("Files found with name '" . $fileName . "': " . $fileCount)

# Method 2: List all files to see what's available
:log info "All files in system:"
:foreach file in=[/file find] do={
    :local name [/file get $file name]
    :log info ("  Found file: " . $name)
}

# Method 3: Try different ways to access file if it exists
:if ($fileCount > 0) do={
    :log info "File exists, testing access methods..."
    
    # Try method 1: Direct file name
    :do {
        :log info "Trying: /file print where name=\"$fileName\""
        /file print where name=$fileName
    } on-error={
        :log warning "Method 1 failed"
    }
    
    # Try method 2: Get first file with matching name
    :do {
        :local fileItem [/file find name=$fileName]
        :log info ("File item found: " . [:tostr $fileItem])
        :log info "Trying to get file properties..."
        /file print where .id=$fileItem
    } on-error={
        :log warning "Method 2 failed"
    }
    
    # Try method 3: Use file operations differently
    :do {
        :log info "Trying to read file contents with different syntax..."
        # In some RouterOS v7 versions, you need to use different commands
        :local content [/file get [/file find name=$fileName] contents]
        :log info ("Content length: " . [:len $content])
    } on-error={
        :log warning "Method 3 failed - contents not supported this way"
    }
    
    # Try method 4: Check if it's an import issue
    :do {
        :log info "Trying alternative file content access..."
        # Some RouterOS versions need special handling for text files
        /file print file=$fileName
    } on-error={
        :log warning "Method 4 failed - print file not supported"
    }
    
} else={
    :log warning "File not found - cannot test access methods"
}

:log info "=== Simple Test Complete ==="