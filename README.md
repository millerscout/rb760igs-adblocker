# RouterOS AdBlock for RB760iGS (hEX S)

This repository provides RouterOS scripts to implement domain-based ad blocking on your RB760iGS router using address lists.

## Quick Start

### Recommended: Incremental Updates (Faster)
1. **Upload the main script to your RouterOS device:**
   - Download `router-scripts/script.rsc` (uses diff file - up to 10,000 new domains)
   - Upload via WinBox, WebFig, or SCP

2. **Run the script:**
   ```bash
   /import file-name=script.rsc
   ```

### Alternative: Full Import (Complete but Slower)
1. **For complete blocklist (all domains):**
   - Download `router-scripts/adblock-full-import.rsc`
   - Upload via WinBox, WebFig, or SCP

2. **Run the full import:**
   ```bash
   /import file-name=adblock-full-import.rsc
   ```

### Setup Firewall Rules (Required)
3. **Set up firewall rules** (if not already configured):
   ```bash
   /ip firewall filter add chain=forward action=drop src-address-list=adblock-list comment="Block Ads"
   ```

## How It Works

### GitHub Actions Automation
- Runs twice monthly (1st and 15th)
- Downloads latest StevenBlack hosts file
- Extracts domains and converts to ASCII encoding for RouterOS compatibility
- Generates two files:
  - `adblock-clean.txt` - Full domain list (ASCII encoded)
  - `adblock-diff.txt` - New domains only (max 10,000, ASCII encoded)

### RouterOS Script Features
- **ASCII Encoding Support** - Compatible with RouterOS v7.19.3+
- **Two Import Options:**
  - **Incremental Updates** - Faster, processes only new domains (recommended)
  - **Full Import** - Complete blocklist, slower but comprehensive
- **Progress Logging** - Detailed status messages
- **Error Handling** - Graceful failure management
- **Automatic Cleanup** - Removes obsolete entries (incremental mode only)

## Files

### Main Scripts (Production Ready)
- `router-scripts/script.rsc` - **Recommended:** Incremental import (diff file, up to 10,000 new domains)
- `router-scripts/adblock-full-import.rsc` - Full import (complete blocklist, slower)

### Testing & Validation Scripts
- `router-scripts/tests/sample-script.rsc` - Test script with 5 sample domains (good first test)
- `router-scripts/tests/validate.rsc` - System validation script
- `router-scripts/tests/test-ascii.rsc` - ASCII file encoding test
- `router-scripts/tests/test-file-read.rsc` - File reading diagnostics
- `router-scripts/tests/test-download.rsc` - Download functionality test
- `router-scripts/tests/simple-test.rsc` - Basic file existence test
- `router-scripts/tests/alt-test.rsc` - Alternative file reading methods

### Sample Data
- `router-scripts/tests/sample-test.txt` - Small test domain list

## Script Comparison

| Script | File Used | Domains | Speed | Use Case |
|--------|-----------|---------|-------|----------|
| `script.rsc` | `adblock-diff.txt` | Up to 10,000 new | ⚡ Fast | Regular updates |
| `adblock-full-import.rsc` | `adblock-clean.txt` | All domains | 🐌 Slower | First setup or full refresh |

**Recommendation:** Use `script.rsc` for regular updates. Use `adblock-full-import.rsc` only for initial setup or when you want to completely refresh the blocklist.

## Testing

### Before First Use - Test with Sample Data
```bash
# Upload and run the sample test first:
/import file-name=tests/sample-script.rsc
```

### Troubleshooting Tools
If you encounter issues, use these diagnostic scripts:
```bash
# Basic system validation:
/import file-name=tests/validate.rsc

# Test file download:
/import file-name=tests/test-download.rsc

# Test ASCII encoding:
/import file-name=tests/test-ascii.rsc
```

## Compatibility

- **RouterOS Version:** v7.19.3+ (tested on RB760iGS)
- **Memory Requirements:** 
  - Incremental updates: ~1.5MB for 10,000 domains
  - Full import: ~3-5MB for complete list
- **Network:** Requires internet access for downloads
- **Processing Time:**
  - Incremental: 2-5 minutes
  - Full import: 10-30 minutes (depending on list size)

## Troubleshooting

### Test the sample first:
```bash
/import file-name=tests/sample-script.rsc
```

### Check logs:
```bash
/log print where message~"AdBlock"
```

### Verify address list:
```bash
/ip firewall address-list print where list="adblock-list" count-only
```

### Diagnostic Scripts:
```bash
# System validation:
/import file-name=tests/validate.rsc

# Test file encoding:
/import file-name=tests/test-ascii.rsc

# Test file reading:
/import file-name=tests/test-file-read.rsc
```

### Common Issues:
1. **"Content length: 0 characters"** - File encoding issue (should be fixed with ASCII encoding)
2. **Download fails** - Check internet connectivity and DNS
3. **Memory errors** - Router may need more available memory

## Manual Setup

If automatic download fails, you can manually upload `adblock-clean.txt` to your router and the script will use the local file.

## License

This project uses domain lists from [StevenBlack/hosts](https://github.com/StevenBlack/hosts) which are under various licenses. Please review their licensing terms.