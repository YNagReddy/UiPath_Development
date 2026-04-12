<!--
  AUTO-GENERATED README - Do not edit manually
  Last updated: 2026-04-12 11:08:03
  To regenerate: .\update_readme.ps1
-->

<div align="center">

# InsightMail - Segregator & Responder

### AI-Powered Email Automation | 100% UiPath Native

[![UiPath](https://img.shields.io/badge/UiPath-Studio_26.0.190.0-orange?style=for-the-badge&logo=uipath)](https://www.uipath.com/)
[![Framework](https://img.shields.io/badge/Framework-REFramework-blue?style=for-the-badge)](https://docs.uipath.com/)
[![GenAI](https://img.shields.io/badge/AI-GenAI_Activities-purple?style=for-the-badge)](https://docs.uipath.com/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen?style=for-the-badge)]()

> **Zero External Code** - No Python, No HTTP Requests, No External APIs
> All AI via UiPath GenAI Activities (Integration Service) + AI Trust Layer

</div>

---

## Overview

**InsightMail_Segregator_Responder** - Robotic Enterprise Framework executing mail segregation and Responder

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

```
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
```

**Pattern**: REFramework + Dispatcher-Performer
**AI Layer**: UiPath GenAI Activities via Integration Service (AI Trust Layer)

---

## Project Structure

```
|-- Data/
|   |-- Input/
|   |   +-- placeholder.txt
|   |-- Output/
|   |   +-- placeholder.txt
|   |-- Temp/
|   |   +-- placeholder.txt
|   |-- ~$Config.xlsx
|   +-- Config.xlsx
|-- Documentation/
|   |-- InsightMail_Testing_Guide.md
|   |-- InsightMail_UiPath_Native_Guide.md
|   +-- REFramework Documentation-EN.pdf
|-- Exceptions_Screenshots/
|   +-- placeholder.txt
|-- Framework/
|   |-- CloseAllApplications.xaml
|   |-- GetTransactionData.xaml
|   |-- InitAllApplications.xaml
|   |-- InitAllSettings.xaml
|   |-- KillAllProcesses.xaml
|   |-- Process.xaml
|   |-- RetryCurrentTransaction.xaml
|   |-- SetTransactionStatus.xaml
|   +-- TakeScreenshot.xaml
|-- Tests/
|   |-- GetTransactionDataTestCase.xaml
|   |-- InitAllApplicationsTestCase.xaml
|   |-- InitAllSettingsTestCase.xaml
|   |-- MainTestCase.xaml
|   |-- ProcessTestCase.xaml
|   |-- Tests.xlsx
|   +-- WorkflowTestCaseTemplate.xaml
|-- entry-points.json
|-- LICENSE
|-- Main.xaml
|-- Main.xaml.json
|-- project.json
|-- project.uiproj
|-- README.md
+-- update_readme.ps1
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `UiPath.Excel.Activities` | 3.4.1 | Excel read/write for logging |
| `UiPath.System.Activities` | 26.2.4 | Core system activities |
| `UiPath.Testing.Activities` | 25.10.2 | Test suite framework |
| `UiPath.UIAutomation.Activities` | 25.10.28 | UI interaction capabilities |

**Runtime**: UiPath Studio 26.0.190.0 | Windows target | VisualBasic | Modern Design Experience

---

## Documentation

The `Documentation/` folder contains comprehensive guides:

### [InsightMail Testing Guide](./Documentation/InsightMail_Testing_Guide.md)

**InsightMail — Testing Guide & Test Data Setup** (1000 lines)

**Sections:**
- 1 — Analysis Summary
- 2 — Test Data Setup
- 3 — Testing Methodologies
- 4 — Test Execution Tracker
- 5 — Test Environment Teardown Checklist
- 6 — Traceability Matrix

---

### [InsightMail UiPath Native Guide](./Documentation/InsightMail_UiPath_Native_Guide.md)

**InsightMail — 100% UiPath Native Implementation Guide** (758 lines)

**Sections:**
- 1 — UiPath GenAI Activities Reference
- 2 — Solution Architecture (100% UiPath Native)
- 3 — Prerequisites & Setup
- 4 — Project Structure
- 5 — Detailed Workflow Design
- 6 — Config.xlsx (REFramework)
- 7 — Excel Output Log Structure
- 8 — Error Handling
- 9 — Step-by-Step Build Guide
- 10 — Why 100% UiPath Native?
- 11 — Licensing & AI Units
- 12 — Interview / Demo Talking Points

---

### [REFramework Documentation-EN](./Documentation/REFramework Documentation-EN.pdf)

Official UiPath reference document (1115 KB PDF)

---


---

## Testing

| Test Case | Purpose |
|-----------|---------|
| `GetTransactionDataTestCase.xaml` | Queue item retrieval and parsing test |
| `InitAllApplicationsTestCase.xaml` | Application initialization test |
| `InitAllSettingsTestCase.xaml` | Config.xlsx and asset loading verification |
| `MainTestCase.xaml` | Full end-to-end workflow validation |
| `ProcessTestCase.xaml` | AI pipeline processing validation |
| `WorkflowTestCaseTemplate.xaml` | Template for creating new test cases |

For comprehensive test data, edge cases, and QA methodology, see the [Testing Guide](./Documentation/InsightMail_Testing_Guide.md).

---

## REFramework Lifecycle

```
INIT ----------> GET TRANSACTION ----------> PROCESS ----------> END
 |                    |                        |                  |
 | InitAllSettings    | GetTransactionData     | Process.xaml     | CloseAll
 | InitAllApps        | (from Queue)           | SetStatus        | KillAll
 |                    |                        |                  |
 |                    <------ Loop ------------+                  |
 |                    (next queue item)                            |
 +-------------- (on fatal error) ------------------------------>+
```

---

## Getting Started

### Prerequisites

- UiPath Studio 26.0+ (Modern Design Experience)
- UiPath Automation Cloud account with Integration Service access
- Email account (Outlook / IMAP / Exchange)
- Orchestrator access (for queues, assets, triggers)

### Quick Start

1. **Clone** the project and open `project.json` in UiPath Studio
2. **Configure** Integration Service connection for GenAI
3. **Set up** Orchestrator Queue (`InsightMail_Emails`) and Credential Asset
4. **Update** `Data/Config.xlsx` with your email folder and settings
5. **Run** the Dispatcher to ingest emails, then the Performer to process them

---

## License

This project is licensed under the **MIT License** -- see the [LICENSE](./LICENSE) file for details.

---

<div align="center">

*Auto-generated on 2026-04-12 11:08:03 by update_readme.ps1*
*Built with UiPath Studio 26.0.190.0 | REFramework | GenAI Activities | AI Trust Layer*

</div>