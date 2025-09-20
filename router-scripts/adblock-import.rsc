# AdBlock Import Script for RouterOS v7 (RB760iGS)
:local adList "adblock-list"

# Always import from the latest diff chunk (adblock-diff.txt)
:local fileName "adblock-diff.txt"
:local fileUrl "https://raw.githubusercontent.com/millerscout/rb760igs-adblocker/main/adblock-diff.txt"

:log info ("AdBlock: Downloading " . $fileUrl)
/tool fetch url=$fileUrl dst-path=$fileName

:log info ("AdBlock: Importing from " . $fileName)

# Disable all existing entries
:foreach i in=[/ip firewall address-list find list=$adList] do={
    /ip firewall address-list set $i disabled=yes
}

# Read file into array
:local fileContent [/file get $fileName contents]
:local start 0
:local end 0
:local len [:len $fileContent]
:while ($start < $len) do={
    :set end [:find $fileContent "\n" $start]
    :if ($end = -1) do={ :set end $len }
    :local domain [:pick $fileContent $start $end]
    :if ([:len $domain] > 0) do={
        :local found false
        :foreach item in=[/ip firewall address-list find list=$adList] do={
            :if ([/ip firewall address-list get $item address] = $domain) do={
                /ip firewall address-list set $item disabled=no
                :set found true
            }
        }
        :if ($found = false) do={
            /ip firewall address-list add list=$adList address=$domain disabled=no
        }
    }
    :set start ($end + 1)
}

# Remove disabled entries (no longer in blocklist)
:foreach i in=[/ip firewall address-list find list=$adList disabled=yes] do={
    /ip firewall address-list remove $i
}

:log info "AdBlock: Import completed!"