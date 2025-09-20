# AdBlock Validation Script for RouterOS v7 (RB760iGS)
:local adList "adblock-list"
:local fileName "adblock-diff.txt"

:log info "=== AdBlock Validation Script ==="

# 1. Check if address list exists and count entries
:local listEntries [:len [/ip firewall address-list find list=$adList]]
:log info ("Address list '" . $adList . "' has " . $listEntries . " entries")

# 2. Check all address lists in system
:local allLists [:len [/ip firewall address-list find]]
:log info ("Total address list entries in system: " . $allLists)

# 3. Show unique list names
:local listNames ""
:foreach item in=[/ip firewall address-list find] do={
    :local currentList [/ip firewall address-list get $item list]
    :if ([:find $listNames $currentList] = -1) do={
        :if ([:len $listNames] > 0) do={ :set listNames ($listNames . ", ") }
        :set listNames ($listNames . $currentList)
    }
}
:if ([:len $listNames] > 0) do={
    :log info ("Address lists found: " . $listNames)
} else={
    :log info "No address lists found in system"
}

# 4. Check if downloaded file exists
:if ([:len [/file find name=$fileName]] > 0) do={
    :local fileSize [/file get $fileName size]
    :log info ("File '" . $fileName . "' exists, size: " . $fileSize . " bytes")
    
    # Show first few lines of file
    :local fileContent [/file get $fileName contents]
    :local pos 0
    :local lineNum 0
    :local len [:len $fileContent]
    
    :while ($pos < $len && $lineNum < 5) do={
        :local nextPos [:find $fileContent "\n" $pos]
        :if ($nextPos = -1) do={ :set nextPos $len }
        :local line [:pick $fileContent $pos $nextPos]
        :if ([:len $line] > 0) do={
            :set lineNum ($lineNum + 1)
            :log info ("Line " . $lineNum . ": '" . $line . "'")
        }
        :set pos ($nextPos + 1)
    }
} else={
    :log info ("File '" . $fileName . "' not found")
}

# 5. Check internet connectivity
:log info "Testing internet connectivity..."
:do {
    /tool fetch url="https://www.google.com" dst-path="test-connectivity.tmp"
    :log info "Internet connectivity: OK"
    /file remove "test-connectivity.tmp"
} on-error={
    :log warning "Internet connectivity: FAILED"
}

# 6. Test address list creation
:log info "Testing address list operations..."
:do {
    /ip firewall address-list add list="test-list" address="test.example.com"
    :log info "Address list add: OK"
    /ip firewall address-list remove [/ip firewall address-list find list="test-list"]
    :log info "Address list remove: OK"
} on-error={
    :log warning "Address list operations: FAILED"
}

:log info "=== Validation Complete ==="