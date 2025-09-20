# RouterOS AdBlock for RB760iGS (hEX S) - Chunked Processing with State Tracking

This repository provides a RouterOS script to implement domain-based ad blocking on your RB760iGS router using address lists. The script uses a chunked file approach to overcome RouterOS memory limitations and includes state tracking for incremental updates.

## Quick Start

### Setup AdBlock (One Script Does Everything)
1. **Upload the script to your RouterOS device:**
   - Download `router-scripts/script.rsc`
   - Upload via WinBox, WebFig, or SCP

2. **Run the script:**
   ```bash
   /import file-name=script.rsc
   ```

3. **Subsequent runs are automatic and incremental:**
   - Script saves state and only processes new chunks
   - Much faster updates after the initial run
   - Automatically detects if full refresh is needed

### Force Full Refresh (Optional)
1. **To force a complete refresh:**
   - Upload `router-scripts/reset-state.rsc`
   - Run: `/import file-name=reset-state.rsc`
   - Then run the main script again

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
- Generates chunked files:
  - `adblock-chunk-1.txt`, `adblock-chunk-2.txt`, etc. - Small files with 500 domains each
  - `adblock-chunks-count.txt` - Control file with total number of chunks

### RouterOS Script Features
- **Chunked File Processing** - Downloads and processes small files sequentially to avoid memory limits
- **Incremental State Tracking** - Saves progress and only processes new chunks on subsequent runs. If interrupted, the script resumes from the last successfully processed chunk.
- **ASCII Encoding Support** - Compatible with RouterOS v7.19.3+
- **Memory Efficient** - Each chunk file is small enough to be read by RouterOS
- **Smart Processing Modes:**
  - **Full Mode** - First run or when chunk count decreases (complete refresh)
  - **Incremental Mode** - Only processes new chunks (much faster)
- **Configurable Logging** - Enable or disable detailed status messages by setting a variable in the script (`enableLogs`).
- **Error Handling** - Graceful failure management with chunk skipping
- **Automatic Cleanup** - Removes obsolete entries and temporary files (full mode only)

## Files

### Main Scripts (Production Ready)
- `router-scripts/script.rsc` - **Main Script:** Chunked processing with incremental state tracking
- `router-scripts/reset-state.rsc` - **Utility:** Reset state to force full refresh

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

## Script Usage

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `script.rsc` | Main ad blocking script | Regular use - handles everything automatically |
| `reset-state.rsc` | Force full refresh | Only when you want to completely rebuild the list |

**Simple Process:** Just run `script.rsc` - it handles full setup on first run and incremental updates thereafter.

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
  - Chunked processing: ~50KB per chunk (very low memory usage)
  - State file: ~10 bytes (tracks last processed chunk count)
- **Network:** Requires internet access for downloads
- **Processing Time:**
  - First run (full): 3-8 minutes (depends on number of chunks)
  - Subsequent runs (incremental): 30 seconds - 2 minutes (only new chunks)

## State Tracking Benefits

**How it works:** The script saves a small state file (`adblock-state.txt`) containing the number of chunks last processed.

**Benefits:**
- **Incremental Updates:** Only downloads and processes new chunks
- **Faster Updates:** Subsequent runs are much faster (only new domains)
- **Automatic Detection:** Script determines if full refresh is needed
- **Smart Recovery:** If chunk count decreases, automatically does full refresh

**Example:**
- First run: 50 chunks available → processes all 50 chunks (full mode)
- Second run: 50 chunks available → no new chunks, exits early
- Third run: 52 chunks available → processes only chunks 51-52 (incremental mode)
- Fourth run: 48 chunks available → processes all 48 chunks (full mode, count decreased)

## Memory Limitations Solved

**Previous Issue:** RouterOS has undocumented memory limitations when reading large file contents (200KB+ files would return 0 characters).

**Solution:** The chunked approach splits large domain lists into small files (500 domains each, ~5-15KB per file) that RouterOS can reliably read and process.

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
1. **"Control file not found"** - Check internet connectivity and GitHub access
2. **Download fails** - Check internet connectivity and DNS  
3. **Chunk skipped** - Non-critical, script continues with other chunks
4. **"Already up to date"** - No new chunks available, working as expected

## Manual Setup

The script automatically downloads all needed files. No manual file uploads are required.

## License

This project uses domain lists from [StevenBlack/hosts](https://github.com/StevenBlack/hosts) which are under various licenses. Please review their licensing terms.