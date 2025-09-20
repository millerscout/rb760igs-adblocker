# Sample AdBlock Test Script for RouterOS v7
:local adList "test-adblock-list"
:local fileName "sample-test.txt"
:local fileUrl "https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/sample-test.txt"

:log info "=== Sample AdBlock Test Started ==="

# Clean up any existing test entries
:log info "Cleaning up existing test entries..."
:foreach item in=[/ip firewall address-list find list=$adList] do={
    /ip firewall address-list remove $item
}

# Download sample file
:log info ("Downloading sample file: " . $fileUrl)
:if ([:len [/file find name=$fileName]] > 0) do={
    /file remove $fileName
}

:do {
    /tool fetch url=$fileUrl dst-path=$fileName
    :delay 2
    
    :if ([:len [/file find name=$fileName]] > 0) do={
        :local fileId [/file find name=$fileName]
        :local fileSize [/file get $fileId size]
        :log info ("Sample file size: " . $fileSize . " bytes")
        
        :if ($fileSize > 0) do={
            :local content [/file get $fileId contents]
            :local contentLength [:len $content]
            :log info ("Content length: " . $contentLength . " characters")
            
            :if ($contentLength > 0) do={
                :log info ("Sample content: '" . $content . "'")
                
                # Parse and add domains
                :local pos 0
                :local addedCount 0
                :local lineEnding "\n"
                
                # Detect line ending
                :if ([:find $content "\r\n"] != -1) do={
                    :set lineEnding "\r\n"
                    :log info "Detected CRLF line endings"
                } else={
                    :log info "Detected LF line endings"
                }
                
                # Process each line
                :while ($pos < $contentLength) do={
                    :local nextPos [:find $content $lineEnding $pos]
                    :if ($nextPos = -1) do={ :set nextPos $contentLength }
                    
                    :local domain [:pick $content $pos $nextPos]
                    # Clean domain
                    :if ([:find $domain "\r"] >= 0) do={
                        :set domain [:pick $domain 0 [:find $domain "\r"]]
                    }
                    :if ([:find $domain "\n"] >= 0) do={
                        :set domain [:pick $domain 0 [:find $domain "\n"]]
                    }
                    
                    :if ([:len $domain] > 0) do={
                        :log info ("Adding domain: '" . $domain . "'")
                        :do {
                            /ip firewall address-list add list=$adList address=$domain
                            :set addedCount ($addedCount + 1)
                            :log info ("Successfully added: " . $domain)
                        } on-error={
                            :log warning ("Failed to add: " . $domain)
                        }
                    }
                    
                    :set pos ($nextPos + [:len $lineEnding])
                }
                
                :log info ("Added " . $addedCount . " domains to test list")
                
                # Verify entries
                :local finalCount [:len [/ip firewall address-list find list=$adList]]
                :log info ("Final test list count: " . $finalCount . " entries")
                
                # Show added entries
                :log info "Added entries:"
                :foreach item in=[/ip firewall address-list find list=$adList] do={
                    :local address [/ip firewall address-list get $item address]
                    :log info ("  - " . $address)
                }
                
            } else={
                :log error "Sample file content is empty!"
            }
        } else={
            :log error "Sample file is empty!"
        }
    } else={
        :log error "Sample file not found after download!"
    }
    
} on-error={
    :log error "Failed to download sample file!"
}

:log info "=== Sample Test Complete ==="
:log info "If this test works, you can run the full script with confidence!"