# RouterOS AdBlock - Test Scripts

This folder contains diagnostic and testing scripts for troubleshooting the RouterOS AdBlock implementation.

## Test Scripts Overview

### 🧪 Basic Functionality Tests

#### `sample-script.rsc`
**Purpose:** Test the complete adblock workflow with a small sample  
**What it does:**
- Downloads 5 test domains from GitHub
- Tests file reading and parsing
- Creates test address list entries
- Verifies the entire process works

**When to use:** First test to run before using main scripts

---

#### `validate.rsc`
**Purpose:** System validation and environment check  
**What it does:**
- Checks existing address lists
- Tests file operations
- Validates internet connectivity
- Shows system capabilities

**When to use:** When troubleshooting system issues

---

### 🔧 File Operation Tests

#### `test-ascii.rsc`
**Purpose:** Test ASCII file encoding compatibility  
**What it does:**
- Downloads and tests ASCII-encoded files
- Verifies RouterOS can read the content
- Shows file encoding status

**When to use:** When getting "Content length: 0" errors

---

#### `test-file-read.rsc`
**Purpose:** Detailed file reading diagnostics  
**What it does:**
- Tests different file reading methods
- Shows line ending types (CRLF vs LF)
- Displays file content samples
- Diagnoses file access issues

**When to use:** When files download but content is empty

---

#### `test-download.rsc`
**Purpose:** Test file download functionality  
**What it does:**
- Tests downloading from GitHub
- Tries alternative URLs
- Shows download status and file sizes

**When to use:** When download appears to fail

---

### 🔍 Advanced Diagnostics

#### `simple-test.rsc`
**Purpose:** Basic file existence and access test  
**What it does:**
- Lists all files on the router
- Tests basic file operations
- Shows file properties

**When to use:** When basic file operations seem broken

---

#### `alt-test.rsc`
**Purpose:** Alternative file reading methods  
**What it does:**
- Tests different RouterOS file access syntax
- Tries various file reading approaches
- Helps identify RouterOS version compatibility

**When to use:** When standard file reading fails

---

## Test Data

#### `sample-test.txt`
Small test file containing 5 domains:
- test1.example.com
- test2.example.com
- test3.example.com
- ads.badsite.com
- tracker.evil.net

## Usage Workflow

### 1. First-Time Setup Testing
```bash
# Test basic functionality:
/import file-name=tests/sample-script.rsc

# If sample works, proceed with main script:
/import file-name=script.rsc
```

### 2. Troubleshooting Failed Downloads
```bash
# Test internet and downloads:
/import file-name=tests/test-download.rsc

# Test file encoding:
/import file-name=tests/test-ascii.rsc
```

### 3. Troubleshooting File Reading Issues
```bash
# Test file reading methods:
/import file-name=tests/test-file-read.rsc

# Try alternative methods:
/import file-name=tests/alt-test.rsc
```

### 4. System Validation
```bash
# Overall system check:
/import file-name=tests/validate.rsc

# Basic file operations:
/import file-name=tests/simple-test.rsc
```

## Expected Results

### ✅ Success Indicators
- "Content successfully read: [number] characters"
- "Added [number] domains to test list"
- "File size: [number] bytes"
- Address list entries created

### ❌ Failure Indicators
- "Content length: 0 characters"
- "File not found"
- "Download failed"
- "Failed to add domain"

## Common Issues and Solutions

| Issue | Likely Cause | Test to Run |
|-------|--------------|-------------|
| Content length: 0 | File encoding | `test-ascii.rsc` |
| Download fails | Network/DNS | `test-download.rsc` |
| File not found | File operations | `simple-test.rsc` |
| Can't read file | RouterOS version | `alt-test.rsc` |
| General issues | System problems | `validate.rsc` |

## Notes

- All test scripts use separate test address lists to avoid interfering with production
- Test scripts include more verbose logging for debugging
- Sample data is hosted on GitHub for consistent testing
- Tests are designed for RouterOS v7.19.3+ but may work on older versions