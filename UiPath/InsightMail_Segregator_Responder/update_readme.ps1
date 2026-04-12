<#
.SYNOPSIS
    Auto-updates README.md for the InsightMail_Segregator_Responder project.

.DESCRIPTION
    Scans the project structure, reads Documentation/*.md files, parses 
    project.json for dependencies/metadata, and regenerates a comprehensive 
    README.md with project details, structure, and documentation summaries.

.USAGE
    Run from the project root:
        .\update_readme.ps1

    Or schedule as a task / Git pre-commit hook:
        powershell -ExecutionPolicy Bypass -File .\update_readme.ps1

.NOTES
    - Safe to re-run: always overwrites README.md
    - Does NOT modify any other files
    - Exit code 0 = success, 1 = error
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReadmePath = Join-Path $ProjectRoot "README.md"
$ProjectJsonPath = Join-Path $ProjectRoot "project.json"
$DocFolder = Join-Path $ProjectRoot "Documentation"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  InsightMail README Auto-Updater" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------
# 1. Parse project.json
# ---------------------------------------------------
Write-Host "[1/5] Parsing project.json..." -ForegroundColor Yellow

$projectJson = Get-Content $ProjectJsonPath -Raw | ConvertFrom-Json
$projectName = $projectJson.name
$projectDesc = $projectJson.description
$projectVersion = $projectJson.projectVersion
$studioVersion = $projectJson.studioVersion
$targetFramework = $projectJson.targetFramework
$expressionLang = $projectJson.expressionLanguage

$depRows = ""
foreach ($dep in $projectJson.dependencies.PSObject.Properties) {
    $pkgName = $dep.Name
    $pkgVersion = $dep.Value -replace '[\[\]]', ''
    $purpose = switch -Wildcard ($pkgName) {
        "*System*"        { "Core system activities" }
        "*UIAutomation*"  { "UI interaction capabilities" }
        "*Excel*"         { "Excel read/write for logging" }
        "*Testing*"       { "Test suite framework" }
        "*Mail*"          { "Email read/send (Outlook, IMAP, Exchange)" }
        "*GenAI*"         { "AI/ML activities (Categorize, Sentiment, Summarize, NER, Generate Email, PII Filter)" }
        default           { "-" }
    }
    $depRows += "| ``$pkgName`` | $pkgVersion | $purpose |`n"
}

Write-Host "  Project: $projectName v$projectVersion" -ForegroundColor Gray
Write-Host "  Studio:  $studioVersion | Target: $targetFramework" -ForegroundColor Gray

# ---------------------------------------------------
# 2. Scan project structure
# ---------------------------------------------------
Write-Host "[2/5] Scanning project structure..." -ForegroundColor Yellow

function Get-ProjectTree {
    param([string]$Path, [string]$Prefix = "", [int]$Depth = 0)
    
    $output = ""
    $items = Get-ChildItem -Path $Path -Force | Sort-Object { -not $_.PSIsContainer }, Name
    $skipDirs = @('.entities', '.local', '.objects', '.project', '.settings', '.templates', '.tmh')
    
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $isLast = ($i -eq $items.Count - 1)
        $connector = if ($isLast) { "+-- " } else { "|-- " }
        $childPrefix = if ($isLast) { "    " } else { "|   " }
        
        if ($item.PSIsContainer) {
            if ($Depth -eq 0 -and $skipDirs -contains $item.Name) {
                continue
            }
            $output += "$Prefix$connector$($item.Name)/`n"
            
            if ($Depth -lt 2) {
                $output += (Get-ProjectTree -Path $item.FullName -Prefix "$Prefix$childPrefix" -Depth ($Depth + 1))
            }
        }
        else {
            $output += "$Prefix$connector$($item.Name)`n"
        }
    }
    return $output
}

$projectTree = Get-ProjectTree -Path $ProjectRoot
Write-Host "  Structure scanned successfully" -ForegroundColor Gray

# ---------------------------------------------------
# 3. Scan Documentation folder
# ---------------------------------------------------
Write-Host "[3/5] Scanning Documentation folder..." -ForegroundColor Yellow

$docSummaries = ""
$docFiles = Get-ChildItem -Path $DocFolder -File | Sort-Object Name

foreach ($doc in $docFiles) {
    $ext = $doc.Extension.ToLower()
    
    if ($ext -eq ".md") {
        $content = Get-Content $doc.FullName -Raw -Encoding UTF8
        $lines = $content -split "`n"
        
        $title = ($lines | Where-Object { $_ -match "^# " } | Select-Object -First 1) -replace "^# ", ""
        $title = $title.Trim()
        $lineCount = $lines.Count
        $sections = @($lines | Where-Object { $_ -match "^# \d" }) | ForEach-Object { ($_ -replace "^# ", "").Trim() }
        
        $relPath = "./Documentation/$($doc.Name)"
        $displayName = $doc.BaseName -replace '_', ' '
        
        $docSummaries += "`n### [$displayName]($relPath)`n`n"
        $docSummaries += "**$title** ($lineCount lines)`n`n"
        
        if ($sections.Count -gt 0) {
            $docSummaries += "**Sections:**`n"
            foreach ($sec in $sections) {
                if ($sec) {
                    $docSummaries += "- $sec`n"
                }
            }
        }
        $docSummaries += "`n---`n"
    }
    elseif ($ext -eq ".pdf") {
        $relPath = "./Documentation/$($doc.Name)"
        $sizeKB = [math]::Round($doc.Length / 1024, 0)
        $displayName = $doc.BaseName -replace '_', ' '
        $docSummaries += "`n### [$displayName]($relPath)`n`n"
        $docSummaries += "Official UiPath reference document (${sizeKB} KB PDF)`n`n---`n"
    }
}

Write-Host "  Found $($docFiles.Count) documentation files" -ForegroundColor Gray

# ---------------------------------------------------
# 4. Scan Tests folder
# ---------------------------------------------------
Write-Host "[4/5] Scanning Tests folder..." -ForegroundColor Yellow

$testsDir = Join-Path $ProjectRoot "Tests"
$testFiles = @()
if (Test-Path $testsDir) {
    $testFiles = @(Get-ChildItem -Path $testsDir -Filter "*.xaml" | Sort-Object Name)
}

$testTable = ""
foreach ($test in $testFiles) {
    $testName = $test.BaseName
    $purpose = switch -Wildcard ($testName) {
        "*Main*"               { "Full end-to-end workflow validation" }
        "*InitAllSettings*"    { "Config.xlsx and asset loading verification" }
        "*InitAllApp*"         { "Application initialization test" }
        "*GetTransaction*"     { "Queue item retrieval and parsing test" }
        "*Process*"            { "AI pipeline processing validation" }
        "*Template*"           { "Template for creating new test cases" }
        default                { "-" }
    }
    $testTable += "| ``$($test.Name)`` | $purpose |`n"
}

Write-Host "  Found $($testFiles.Count) test cases" -ForegroundColor Gray

# ---------------------------------------------------
# 5. Build README.md
# ---------------------------------------------------
Write-Host "[5/5] Generating README.md..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$readme = @"
<!--
  AUTO-GENERATED README - Do not edit manually
  Last updated: $timestamp
  To regenerate: .\update_readme.ps1
-->

<div align="center">

# InsightMail - Segregator & Responder

### AI-Powered Email Automation | 100% UiPath Native

[![UiPath](https://img.shields.io/badge/UiPath-Studio_$($studioVersion)-orange?style=for-the-badge&logo=uipath)](https://www.uipath.com/)
[![Framework](https://img.shields.io/badge/Framework-REFramework-blue?style=for-the-badge)](https://docs.uipath.com/)
[![GenAI](https://img.shields.io/badge/AI-GenAI_Activities-purple?style=for-the-badge)](https://docs.uipath.com/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)
[![Version](https://img.shields.io/badge/Version-$projectVersion-brightgreen?style=for-the-badge)]()

> **Zero External Code** - No Python, No HTTP Requests, No External APIs
> All AI via UiPath GenAI Activities (Integration Service) + AI Trust Layer

</div>

---

## Overview

**$projectName** - $projectDesc

This enterprise-grade automation reads incoming emails, intelligently categorizes them into 7 categories, analyzes sentiment with confidence scoring, summarizes content, extracts key entities, and generates contextual replies -- all using native UiPath GenAI Activities without a single line of external code.

| Capability | How |
|-----------|-----|
| **Email Ingestion** | Reads unread emails via Outlook/IMAP/Exchange |
| **Smart Categorization** | Classifies into: Complaint, Request, Inquiry, Escalation, Info, Feedback, Urgent |
| **Sentiment Analysis** | Detects tone (Positive/Neutral/Negative) with confidence scoring |
| **Summarization** | Generates concise 50-75 word summaries of email threads |
| **Entity Extraction** | Pulls names, dates, invoice numbers, amounts via NER |
| **Priority Assessment** | AI-driven High/Medium/Low priority classification |
| **Reply Generation** | Drafts contextual, tone-matching professional replies |
| **PII Filtering** | Redacts sensitive data (SSN, credit cards, phone numbers) before logging |
| **Smart Routing** | Escalates to Action Center or auto-replies based on category + confidence |

---

## Architecture

``````
EMAIL INBOX --> DISPATCHER --> ORCHESTRATOR QUEUE --> PERFORMER
                (Read &         (InsightMail_         (AI Pipeline
                 Sanitize)        Emails)               + Action)

PERFORMER AI PIPELINE:
+----------------------------------------------------------+
| 1. Detect Language  ->  2. Categorize  ->  3. Sentiment  |
| 4. Summarize  ->  5. Extract Entities  ->  6. Priority   |
| 7. Generate Reply  ->  8. PII Filter (optional)          |
+-----------------------------+----------------------------+
                              |
               +--- DECISION ENGINE ---+
               | High/Escalation -> Action Center (human review)
               | Request/Inquiry -> Auto-reply (if confidence >= 80%)
               | Info/Feedback   -> Log only
               +--- -> Excel Log ------+
``````

**Pattern**: REFramework + Dispatcher-Performer
**AI Layer**: UiPath GenAI Activities via Integration Service (AI Trust Layer)

---

## Project Structure

``````
$projectTree``````

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
$depRows
**Runtime**: UiPath Studio $studioVersion | $targetFramework target | $expressionLang | Modern Design Experience

---

## Documentation

The ``Documentation/`` folder contains comprehensive guides:
$docSummaries

---

## Testing

| Test Case | Purpose |
|-----------|---------|
$testTable
For comprehensive test data, edge cases, and QA methodology, see the [Testing Guide](./Documentation/InsightMail_Testing_Guide.md).

---

## REFramework Lifecycle

``````
INIT ----------> GET TRANSACTION ----------> PROCESS ----------> END
 |                    |                        |                  |
 | InitAllSettings    | GetTransactionData     | Process.xaml     | CloseAll
 | InitAllApps        | (from Queue)           | SetStatus        | KillAll
 |                    |                        |                  |
 |                    <------ Loop ------------+                  |
 |                    (next queue item)                            |
 +-------------- (on fatal error) ------------------------------>+
``````

---

## Getting Started

### Prerequisites

- UiPath Studio 26.0+ (Modern Design Experience)
- UiPath Automation Cloud account with Integration Service access
- Email account (Outlook / IMAP / Exchange)
- Orchestrator access (for queues, assets, triggers)

### Quick Start

1. **Clone** the project and open ``project.json`` in UiPath Studio
2. **Configure** Integration Service connection for GenAI
3. **Set up** Orchestrator Queue (``InsightMail_Emails``) and Credential Asset
4. **Update** ``Data/Config.xlsx`` with your email folder and settings
5. **Run** the Dispatcher to ingest emails, then the Performer to process them

---

## License

This project is licensed under the **MIT License** -- see the [LICENSE](./LICENSE) file for details.

---

<div align="center">

*Auto-generated on $timestamp by update_readme.ps1*
*Built with UiPath Studio $studioVersion | REFramework | GenAI Activities | AI Trust Layer*

</div>
"@

# ---------------------------------------------------
# Write or display
# ---------------------------------------------------
if ($DryRun) {
    Write-Host ""
    Write-Host "=== DRY RUN - README content: ===" -ForegroundColor Magenta
    Write-Host $readme
}
else {
    [System.IO.File]::WriteAllText($ReadmePath, $readme, [System.Text.Encoding]::UTF8)
    Write-Host ""
    Write-Host "[OK] README.md updated successfully!" -ForegroundColor Green
    Write-Host "   Path: $ReadmePath" -ForegroundColor Gray
    
    $readmeSize = (Get-Item $ReadmePath).Length
    $readmeLines = (Get-Content $ReadmePath).Count
    Write-Host "   Size: $readmeSize bytes ($readmeLines lines)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Done!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
