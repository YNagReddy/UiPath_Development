# InsightMail — 100% UiPath Native Implementation Guide

## AI-Powered Email Automation Using UiPath GenAI Activities

> **Zero External Code** — No Python, no HTTP requests, no external APIs  
> **All AI via**: UiPath GenAI Activities (Integration Service)  
> **Package**: `UiPath.GenAI.Activities` (via Integration Service connector)  
> **Framework**: REFramework + Dispatcher-Performer

---

# 1 — UiPath GenAI Activities Reference

## Package: UiPath GenAI Activities (Integration Service)

All activities below are available natively inside UiPath Studio. They use UiPath-managed LLMs via the **AI Trust Layer** — no external API keys or subscriptions needed.

### Activities Used in InsightMail

| # | Activity Name | Package Location | Purpose in InsightMail |
|---|--------------|------------------|----------------------|
| 1 | **Categorize** | GenAI Activities | Classify email into Complaint / Request / Inquiry / Escalation / Info / Feedback / Urgent |
| 2 | **Sentiment Analysis** | GenAI Activities | Detect email tone: Positive / Neutral / Negative + confidence score + key phrases |
| 3 | **Summarize Text** | GenAI Activities | Generate 2-3 sentence summary of email body with key points |
| 4 | **Named Entity Recognition** | GenAI Activities | Extract entities: customer names, dates, invoice numbers, amounts |
| 5 | **Generate Email** | GenAI Activities | Draft contextual, tone-matching reply based on email content |
| 6 | **Content Generation** | GenAI Activities | Custom prompts for priority assessment or additional analysis |
| 7 | **PII Filtering** | GenAI Activities | Detect and redact sensitive info before logging (optional) |
| 8 | **Detect Language** | GenAI Activities | Identify email language for multi-language support |
| 9 | **Translate** | GenAI Activities | Translate non-English emails before processing (optional) |
| 10 | **Rewrite** | GenAI Activities | Rewrite draft reply to match specific tone/style guidelines |

### Other Available GenAI Activities (Not Used in InsightMail, But Available)

| Activity | Purpose |
|----------|---------|
| Reformat | Restructure text output format |
| Semantic Similarity | Compare meaning of two texts |
| Image Analysis | Analyze images (invoices, receipts) |
| Image Classification | Classify images into categories |
| Detect Object | Identify objects in images |
| Image Comparison | Compare two images |
| Signature Similarity | Compare signatures |
| Context Grounding Search | RAG — query indexed data |
| Update Context Grounding Index | Manage RAG index data |
| Web Search | Search the web from workflow |
| Web Summary | Summarize web content |
| Web Reader | Extract and read web content |

---

# 2 — Solution Architecture (100% UiPath Native)

```
┌──────────────────────────────────────────────────────────────────┐
│                    INSIGHTMAIL — UiPath Native                   │
│                                                                  │
│  ┌─── EMAIL INGESTION (UiPath Mail Activities) ─────────────┐   │
│  │  Get Mail Messages (Outlook/IMAP/Exchange)                │   │
│  │  Filter: Unread + Target Folder                           │   │
│  │  Output: List<MailMessage>                                │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                              ↓                                   │
│  ┌─── ORCHESTRATOR QUEUE ───┼───────────────────────────────┐   │
│  │  Queue: InsightMail_Emails                                │   │
│  │  Each email → 1 Queue Item                                │   │
│  │  SpecificContent: Subject, Body, Sender, Date             │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                              ↓                                   │
│  ┌─── AI PROCESSING (UiPath GenAI Activities) ──────────────┐   │
│  │                                                            │   │
│  │  STEP 1: Detect Language                                   │   │
│  │  → Identify language, translate if non-English             │   │
│  │                                                            │   │
│  │  STEP 2: Categorize                                        │   │
│  │  → Input: email body                                       │   │
│  │  → Categories: Complaint, Request, Inquiry, Escalation,    │   │
│  │                 Info, Feedback, Urgent                      │   │
│  │  → Output: category (String)                               │   │
│  │                                                            │   │
│  │  STEP 3: Sentiment Analysis                                │   │
│  │  → Input: email body                                       │   │
│  │  → Output: sentiment, score, confidence, key phrases       │   │
│  │                                                            │   │
│  │  STEP 4: Summarize Text                                    │   │
│  │  → Input: email body                                       │   │
│  │  → Format: Paragraph / Bulleted list                       │   │
│  │  → Target Length: 50-75 words                              │   │
│  │  → Output: summary (String)                                │   │
│  │                                                            │   │
│  │  STEP 5: Named Entity Recognition                          │   │
│  │  → Input: email body                                       │   │
│  │  → Output: entities JSON (names, dates, IDs, amounts)      │   │
│  │                                                            │   │
│  │  STEP 6: Content Generation (Priority Assessment)          │   │
│  │  → Prompt: "Based on category + sentiment, assign priority"│   │
│  │  → Output: High / Medium / Low                             │   │
│  │                                                            │   │
│  │  STEP 7: Generate Email (Reply Draft)                      │   │
│  │  → Input: email context + category + summary               │   │
│  │  → Writing Style: Professional / Empathetic                │   │
│  │  → Output: reply body (String)                             │   │
│  │                                                            │   │
│  │  STEP 8 (Optional): PII Filtering                          │   │
│  │  → Scan email body before logging                          │   │
│  │  → Redact SSN, credit card, phone numbers                  │   │
│  │                                                            │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                              ↓                                   │
│  ┌─── DECISION & ACTION ────┼───────────────────────────────┐   │
│  │                                                            │   │
│  │  IF priority == "High" OR category == "Escalation"         │   │
│  │     → Create Action Center Task for manager                │   │
│  │                                                            │   │
│  │  ELSE IF category IN ("Request", "Inquiry")                │   │
│  │     → Auto-send GenAI-drafted reply                        │   │
│  │                                                            │   │
│  │  ELSE IF category IN ("Info", "Feedback")                  │   │
│  │     → Log only, no reply                                   │   │
│  │                                                            │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                              ↓                                   │
│  ┌─── LOGGING (Excel / Data Service) ───────────────────────┐   │
│  │  Append Range → EmailProcessingLog.xlsx                    │   │
│  │  Columns: Timestamp, Sender, Subject, Category, Priority, │   │
│  │  Sentiment, Summary, Entities, Reply Sent, Action Taken    │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

# 3 — Prerequisites & Setup

## Step 1: Install UiPath Studio

- UiPath Studio (Community or Enterprise) — **Modern Design Experience**
- Compatible with: Windows - Legacy, Windows, Cross-platform projects

## Step 2: Set Up Integration Service Connection

```
1. Go to UiPath Automation Cloud → Integration Service
2. Click "Add Connection"
3. Search for "UiPath GenAI"
4. Click "Connect" → Authenticate
5. Connection is now available in all GenAI activities

NOTE: No external API key needed. UiPath manages the LLM infrastructure
via its AI Trust Layer. Your data is NOT used for model training.
```

## Step 3: Install NuGet Packages

| Package | Purpose |
|---------|---------|
| `UiPath.Mail.Activities` | Read/Send emails (Outlook, IMAP, Exchange) |
| `UiPath.GenAI.Activities` | Auto-added when using Integration Service GenAI activities |
| `Newtonsoft.Json` | JSON parsing (usually pre-installed) |

## Step 4: Orchestrator Setup

| Item | Configuration |
|------|--------------|
| **Queue** | `InsightMail_Emails` — Unique Reference: Yes, Max Retries: 2 |
| **Asset** | `InsightMail_EmailCredential` (Credential) — Email login |
| **Trigger (Dispatcher)** | Time Trigger — every 15 minutes |
| **Trigger (Performer)** | Queue Trigger — min items: 1, max concurrent: 3 |

---

# 4 — Project Structure

```
InsightMail/
│
├── project.json
├── Config.xlsx                           ← REFramework settings
│
├── Main.xaml                             ← REFramework entry point
├── Framework/
│   ├── InitAllSettings.xaml
│   ├── InitAllApplications.xaml
│   ├── GetTransactionData.xaml
│   ├── Process.xaml                      ← Core AI processing
│   ├── SetTransactionStatus.xaml
│   ├── CloseAllApplications.xaml
│   └── KillAllProcesses.xaml
│
├── Workflows/
│   ├── Email/
│   │   ├── ReadIncomingEmails.xaml        ← Dispatcher — fetch + queue
│   │   ├── SanitizeEmailBody.xaml         ← Strip HTML tags
│   │   └── SendReply.xaml                 ← Send AI reply
│   │
│   ├── AI/
│   │   ├── CategorizeEmail.xaml           ← GenAI: Categorize
│   │   ├── AnalyzeSentiment.xaml          ← GenAI: Sentiment Analysis
│   │   ├── SummarizeEmail.xaml            ← GenAI: Summarize Text
│   │   ├── ExtractEntities.xaml           ← GenAI: Named Entity Recognition
│   │   ├── AssessPriority.xaml            ← GenAI: Content Generation
│   │   ├── GenerateReply.xaml             ← GenAI: Generate Email
│   │   └── FilterPII.xaml                 ← GenAI: PII Filtering (optional)
│   │
│   ├── Actions/
│   │   ├── RouteByCategory.xaml           ← Decision logic
│   │   ├── CreateEscalation.xaml          ← Action Center task
│   │   └── LogResult.xaml                 ← Write to Excel
│   │
│   └── Utilities/
│       └── TruncateText.xaml              ← Limit text length
│
└── Data/
    ├── Input/
    └── Output/
        └── EmailProcessingLog.xlsx
```

---

# 5 — Detailed Workflow Design

## 5.1 — Dispatcher: ReadIncomingEmails.xaml

```
PURPOSE: Read unread emails → add each to Orchestrator Queue

ACTIVITIES:

1. Get Mail Messages (IMAP / Outlook / Exchange)
   ├── MailFolder: "Inbox"
   ├── OnlyUnreadMessages: True
   ├── Top: 50
   └── Output: mailMessages (List<MailMessage>)

2. For Each: email In mailMessages
   │
   ├── 2a. Assign variables
   │   ├── emailSubject = email.Subject
   │   ├── emailSender  = email.From.Address
   │   ├── emailDate    = email.Date.ToString("yyyy-MM-dd HH:mm:ss")
   │   └── emailId      = email.Headers("Message-ID")
   │
   ├── 2b. Invoke SanitizeEmailBody.xaml
   │   ├── Input: email.Body
   │   └── Output: cleanBody
   │   │   (Uses Assign: Regex.Replace(rawBody, "<[^>]+>", ""))
   │   │   (Uses Assign: Trim whitespace, normalize line breaks)
   │
   ├── 2c. Invoke TruncateText.xaml
   │   ├── Input: cleanBody, maxLength = 4000
   │   └── Output: truncatedBody
   │
   ├── 2d. Add Queue Item
   │   ├── QueueName: "InsightMail_Emails"
   │   ├── Reference: emailId
   │   └── ItemInformation:
   │       ├── "Subject"    → emailSubject
   │       ├── "Body"       → truncatedBody
   │       ├── "Sender"     → emailSender
   │       └── "ReceivedAt" → emailDate
   │
   └── 2e. Mark email as Read
```

## 5.2 — Performer Process.xaml (Core AI Pipeline)

```
PURPOSE: Pick queue item → process through GenAI activities → act → log

INPUT: in_TransactionItem (QueueItem)

═══════════════════════════════════════════════════════════
STEP 1: EXTRACT DATA FROM QUEUE ITEM
═══════════════════════════════════════════════════════════

Assign: emailSubject = in_TransactionItem.SpecificContent("Subject").ToString
Assign: emailBody    = in_TransactionItem.SpecificContent("Body").ToString
Assign: emailSender  = in_TransactionItem.SpecificContent("Sender").ToString
Assign: emailDate    = in_TransactionItem.SpecificContent("ReceivedAt").ToString


═══════════════════════════════════════════════════════════
STEP 2: CATEGORIZE (GenAI Activity: Categorize)
═══════════════════════════════════════════════════════════

Activity: Categorize
├── Connection: [GenAI Integration Service connection]
├── Content: emailSubject + " " + emailBody
├── Categories: "Complaint, Request, Inquiry, Escalation, Info, Feedback, Urgent"
└── Output: categoryResult (String)
    → Example: "Complaint"

Assign: emailCategory = categoryResult


═══════════════════════════════════════════════════════════
STEP 3: SENTIMENT ANALYSIS (GenAI Activity: Sentiment Analysis)
═══════════════════════════════════════════════════════════

Activity: Sentiment Analysis
├── Connection: [GenAI Integration Service connection]
├── Text: emailBody
└── Output: sentimentResult (String — JSON format)

Deserialize JSON: sentimentResult → sentimentObj (JObject)
Assign: overallSentiment  = sentimentObj("overall_sentiment").ToString
                            → Example: "Negative"
Assign: sentimentScore    = CDbl(sentimentObj("sentiment_score"))
                            → Example: -0.78
Assign: confidenceLevel   = CDbl(sentimentObj("confidence"))
                            → Example: 0.92
Assign: keyPhrases        = sentimentObj("key_phrases").ToString
                            → Example: "overdue payment, third reminder, legal department"


═══════════════════════════════════════════════════════════
STEP 4: SUMMARIZE TEXT (GenAI Activity: Summarize Text)
═══════════════════════════════════════════════════════════

Activity: Summarize Text
├── Connection: [GenAI Integration Service connection]
├── Text to summarize: emailBody
├── Summary format: "Paragraph"    (Options: Paragraph, Bulleted, Numbered)
├── Target length: 75              (words)
├── Detect language for output: True
└── Output: summaryResult (String)
    → Example: "Client James Morrison from Morrison & Partners reports that
       Invoice #INV-2024-0892 for $45,230 remains unpaid past the March 15
       deadline. This is their third reminder and they are threatening legal
       action within 48 hours if payment is not processed."


═══════════════════════════════════════════════════════════
STEP 5: NAMED ENTITY RECOGNITION (GenAI Activity: NER)
═══════════════════════════════════════════════════════════

Activity: Named Entity Recognition
├── Connection: [GenAI Integration Service connection]
├── Input: emailBody
└── Output: entitiesResult (String — JSON format)

Deserialize JSON: entitiesResult → entitiesObj (JObject)
    → Example parsed entities:
    {
      "persons": ["James Morrison"],
      "organizations": ["Morrison & Partners LLC"],
      "dates": ["March 15, 2026", "48 hours"],
      "amounts": ["$45,230.00"],
      "references": ["INV-2024-0892"],
      "roles": ["Senior Accounts Manager"]
    }

Assign: extractedEntities = entitiesResult  (store full JSON string)


═══════════════════════════════════════════════════════════
STEP 6: PRIORITY ASSESSMENT (GenAI Activity: Content Generation)
═══════════════════════════════════════════════════════════

Activity: Content Generation
├── Connection: [GenAI Integration Service connection]
├── Prompt: "Based on the following email analysis, assign a priority level.
│            Category: " + emailCategory + "
│            Sentiment: " + overallSentiment + "
│            Confidence: " + sentimentScore.ToString + "
│            Key phrases: " + keyPhrases + "
│            
│            Rules:
│            - Escalation or Complaint with Negative sentiment = High
│            - Request with Neutral sentiment = Medium
│            - Info or Feedback = Low
│            - If key phrases include 'legal', 'urgent', 'deadline' = High
│            
│            Respond with ONLY one word: High, Medium, or Low"
├── System Prompt: "You are a priority classifier. Respond with exactly one
│                   word: High, Medium, or Low."
└── Output: priorityResult (String)

Assign: emailPriority = priorityResult.Trim()
    → Example: "High"


═══════════════════════════════════════════════════════════
STEP 7: GENERATE REPLY (GenAI Activity: Generate Email)
═══════════════════════════════════════════════════════════

IF emailCategory <> "Info" THEN

    Activity: Generate Email
    ├── Connection: [GenAI Integration Service connection]
    ├── Email Content/Prompt: "Write a professional reply to this email.
    │                          
    │                          Original email from: " + emailSender + "
    │                          Subject: " + emailSubject + "
    │                          Summary: " + summaryResult + "
    │                          Category: " + emailCategory + "
    │                          Sentiment: " + overallSentiment + "
    │                          
    │                          Guidelines:
    │                          - Acknowledge the sender's concern
    │                          - Be empathetic if sentiment is negative
    │                          - Provide next steps or resolution timeline
    │                          - Do not fabricate specific dates or ticket numbers
    │                          - Keep reply to 3-5 sentences"
    ├── Writing style: "Professional"
    │   (Use "Empathetic" if category == "Complaint")
    ├── Salutation: "Dear " + senderName
    ├── Sign-off: "Best regards"
    ├── Output format: "Text"
    └── Output: replyBody (String)

ELSE
    Assign: replyBody = "NO_REPLY_NEEDED"

END IF


═══════════════════════════════════════════════════════════
STEP 8: PII FILTERING — Optional (GenAI Activity: PII Filtering)
═══════════════════════════════════════════════════════════

Activity: PII Filtering
├── Connection: [GenAI Integration Service connection]
├── Input: emailBody
└── Output: filteredBody (String)
    → SSNs, credit cards, phone numbers redacted for logging

Assign: safeBodyForLog = filteredBody


═══════════════════════════════════════════════════════════
STEP 9: ROUTE & ACT (Invoke RouteByCategory.xaml)
═══════════════════════════════════════════════════════════

IF emailPriority == "High" OR emailCategory == "Escalation"

    → Create Action Center Task
      ├── Title: "[ESCALATION] " + emailSubject
      ├── Priority: High
      ├── Data:
      │   ├── Sender: emailSender
      │   ├── Category: emailCategory
      │   ├── Summary: summaryResult
      │   ├── Entities: extractedEntities
      │   ├── Suggested Reply: replyBody
      │   └── Sentiment: overallSentiment
      └── Assign To: "AP_Manager"

    Assign: actionTaken = "Escalated to Action Center"
    Assign: replySent = "No"

ELSE IF emailCategory IN ("Request", "Inquiry") AND
        confidenceLevel >= 0.80

    → Invoke SendReply.xaml
      ├── To: emailSender
      ├── Subject: "Re: " + emailSubject
      ├── Body: replyBody + vbCrLf + vbCrLf +
      │         "---" + vbCrLf +
      │         "This response was generated by InsightMail."
      └── IsBodyHtml: False

    Assign: actionTaken = "Auto-replied"
    Assign: replySent = "Yes"

ELSE IF emailCategory IN ("Info", "Feedback")

    Assign: actionTaken = "Logged — no action needed"
    Assign: replySent = "No"

ELSE

    Assign: actionTaken = "Queued for manual review"
    Assign: replySent = "No"

END IF


═══════════════════════════════════════════════════════════
STEP 10: LOG RESULT (Invoke LogResult.xaml)
═══════════════════════════════════════════════════════════

Build DataRow with values:
├── DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
├── emailSender
├── emailSubject
├── emailCategory
├── emailPriority
├── overallSentiment
├── sentimentScore.ToString
├── summaryResult
├── extractedEntities (first 500 chars)
├── replyBody (first 500 chars)
├── replySent
├── actionTaken
└── "Success"

Append Range: EmailProcessingLog.xlsx
├── Sheet: "ProcessingLog"
├── DataTable: single-row DataTable with above values
```

---

# 6 — Config.xlsx (REFramework)

## Settings Sheet

| Name | Value | Description |
|------|-------|-------------|
| `logF_BusinessProcessName` | InsightMail | Process name |
| `EmailFolder` | Inbox | Target email folder |
| `MaxEmailsPerRun` | 50 | Batch size |
| `UnreadOnly` | True | Process only unread |
| `MaxBodyLength` | 4000 | Truncate body for AI activities |
| `AutoReplyCategories` | Request,Inquiry | Categories that allow auto-reply |
| `EscalationCategories` | Escalation,Complaint | Categories that escalate |
| `ConfidenceThreshold` | 0.80 | Min confidence for auto-reply |
| `SummaryWordCount` | 75 | Target summary length |
| `SummaryFormat` | Paragraph | Paragraph, Bulleted, or Numbered |
| `OutputLogPath` | Data\Output\EmailProcessingLog.xlsx | Log file path |

## Constants Sheet

| Name | Value |
|------|-------|
| `MaxRetryNumber` | 2 |
| `QueueName` | InsightMail_Emails |

---

# 7 — Excel Output Log Structure

### EmailProcessingLog.xlsx

| Column | Example Value |
|--------|---------------|
| **Timestamp** | 2026-04-11 10:30:22 |
| **Sender** | <james.morrison@morrisonpartners.com> |
| **Subject** | Urgent: Invoice #INV-2024-0892 payment overdue |
| **Category** | Escalation |
| **Priority** | High |
| **Sentiment** | Negative |
| **Sentiment_Score** | -0.78 |
| **Summary** | Client reports overdue invoice #INV-2024-0892 for $45,230... |
| **Entities** | {"persons":["James Morrison"],"amounts":["$45,230"],...} |
| **Reply_Text** | Dear Mr. Morrison, Thank you for bringing this to our... |
| **Reply_Sent** | No |
| **Action_Taken** | Escalated to Action Center |
| **Status** | Success |

---

# 8 — Error Handling

## REFramework Exception Strategy

| Exception Type | Scenario | Handling |
|---------------|----------|----------|
| **Business Rule** | Category = "Unknown" | Log as failed, skip to next |
| **Business Rule** | Email body empty | Skip, mark as business exception |
| **Application** | GenAI activity timeout | Retry (max 2x via REFramework) |
| **Application** | Integration Service connection failed | Retry once, then log and skip |
| **Application** | Email send failed | Retry 2x, log error |
| **Application** | Excel write failed | Retry once, log to Orchestrator |

## Try-Catch Structure in Process.xaml

```
Try
    ├── STEP 2: Categorize  (Try-Catch inside)
    ├── STEP 3: Sentiment Analysis
    ├── STEP 4: Summarize Text
    ├── STEP 5: Named Entity Recognition
    ├── STEP 6: Priority Assessment
    ├── STEP 7: Generate Reply
    ├── STEP 9: Route & Act
    └── STEP 10: Log Result

Catch BusinessRuleException
    ├── Set Transaction Status: Failed (Business)
    ├── Log: "Business exception for email from " + emailSender
    └── Continue to next transaction

Catch System.Exception
    ├── Set Transaction Status: Failed (Application)
    ├── Log: "System error: " + exception.Message
    └── REFramework retries (up to MaxRetryNumber)
```

---

# 9 — Step-by-Step Build Guide

## Phase 1: Setup (Day 1)

```
✅ Create new UiPath project: "InsightMail" (Modern Design)
✅ Download REFramework template → copy into project
✅ Configure Config.xlsx with InsightMail settings
✅ Set up Integration Service connection for GenAI
✅ Create Orchestrator Queue: InsightMail_Emails
✅ Create Orchestrator Asset: InsightMail_EmailCredential
✅ Install packages: UiPath.Mail.Activities
```

## Phase 2: Dispatcher (Day 2)

```
✅ Build ReadIncomingEmails.xaml
   - Get Mail Messages (IMAP or Outlook)
   - Test: verify emails are read correctly
✅ Build SanitizeEmailBody.xaml
   - Regex.Replace to strip HTML
✅ Build dispatcher flow: read → sanitize → add to queue
✅ Test: send 5 test emails → verify 5 queue items in Orchestrator
```

## Phase 3: AI Activities (Day 3-4)

```
✅ Build CategorizeEmail.xaml
   - Drag "Categorize" activity
   - Set categories string
   - Test with sample email → verify correct category

✅ Build AnalyzeSentiment.xaml
   - Drag "Sentiment Analysis" activity
   - Deserialize JSON output
   - Test: complaint email → "Negative" sentiment

✅ Build SummarizeEmail.xaml
   - Drag "Summarize Text" activity
   - Set format and target length
   - Test: long email → concise summary

✅ Build ExtractEntities.xaml
   - Drag "Named Entity Recognition" activity
   - Deserialize JSON output
   - Test: invoice email → extracts names, amounts, dates

✅ Build AssessPriority.xaml
   - Drag "Content Generation" activity
   - Write priority assessment prompt
   - Test: escalation + negative → "High"

✅ Build GenerateReply.xaml
   - Drag "Generate Email" activity
   - Configure writing style, salutation, sign-off
   - Test: complaint → empathetic reply
```

## Phase 4: Performer (Day 5-6)

```
✅ Build Process.xaml (chain all AI workflows)
✅ Build RouteByCategory.xaml (decision logic)
✅ Build SendReply.xaml (send SMTP/Outlook)
✅ Build LogResult.xaml (append to Excel)
✅ End-to-end test: email → queue → AI → act → log
```

## Phase 5: Testing & Deploy (Day 7)

```
✅ Test all 7 email categories:
   - Complaint (negative sentiment) → escalate
   - Request (neutral) → auto-reply
   - Inquiry (neutral) → auto-reply
   - Escalation (urgent) → Action Center
   - Info (neutral) → log only
   - Feedback (positive) → log only
   - Urgent (negative) → escalate

✅ Test edge cases:
   - Empty email body
   - Very long email (10K+ chars)
   - Non-English email
   - Email with only attachment (no body)

✅ Publish to Orchestrator
✅ Configure triggers
✅ Monitor first 24 hours
```

---

# 10 — Why 100% UiPath Native?

| Factor | UiPath GenAI Native | Python + External API |
|--------|---------------------|----------------------|
| **Setup complexity** | ✅ Zero — drag & drop | ❌ Install Python, pip, manage dependencies |
| **API key management** | ✅ No keys needed — UiPath AI Trust Layer manages | ❌ Need OpenAI/Anthropic account + manage keys |
| **Data security** | ✅ UiPath AI Trust Layer — data not used for training | ⚠️ Data sent to third-party APIs |
| **Cost** | ✅ Included with AI Units (licensing) | ❌ Pay per token to OpenAI/Anthropic |
| **Maintenance** | ✅ UiPath manages model updates | ❌ Must track API versions, SDK updates |
| **Error handling** | ✅ Native UiPath retry, integrated with REFramework | ❌ Must build custom retry logic in Python |
| **Deployment** | ✅ Single package — no Python runtime on bot machines | ❌ Python + packages must be on every bot runner |
| **Governance** | ✅ Full audit via Orchestrator + Insights | ❌ Custom logging needed |
| **Scalability** | ✅ UiPath handles model scaling | ❌ Must manage API rate limits |
| **Learning curve** | ✅ Same UiPath Studio — no coding | ❌ Requires Python proficiency |

---

# 11 — Licensing & AI Units

```
GenAI Activities consume AI Units or Platform Units:

AI Units (Flex Plan):
  - Each GenAI activity execution = X AI Units
  - Varies by activity type and text length
  - Categorize, Sentiment, Summarize = smaller unit consumption
  - Content Generation = larger unit consumption

Platform Units (Unified Pricing):
  - GenAI activities included in Platform Unit allocation

Recommendation for InsightMail:
  - 7 GenAI activities per email × 200 emails/day = 1,400 activity calls/day
  - Monitor AI Unit consumption via Orchestrator Insights
  - Optimize: combine steps where possible using Content Generation
```

---

# 12 — Interview / Demo Talking Points

## "How InsightMail Works" (Elevator Pitch)

> "InsightMail is an AI-powered email automation built **entirely in UiPath** using native GenAI Activities — **zero external code**. It reads incoming emails, uses UiPath's built-in AI to categorize, analyze sentiment, summarize, extract entities, and generate contextual replies. High-priority items escalate to managers via Action Center. Routine inquiries get auto-replied. Everything is logged for audit."

## Technical Deep-Dive Points

1. **"We use 7 native GenAI activities"** — Categorize, Sentiment Analysis, Summarize Text, Named Entity Recognition, Content Generation, Generate Email, PII Filtering

2. **"No Python, no external APIs"** — Everything runs through UiPath Integration Service + AI Trust Layer. No API keys to manage, no Python dependencies to install on bot runners.

3. **"REFramework + Dispatcher-Performer"** — Enterprise-grade architecture with queue-based processing, retry logic, and exception handling.

4. **"Confidence-based routing"** — Auto-replies only when sentiment confidence > 80%. Low confidence or high-priority emails go to Action Center for human review.

5. **"Full audit trail"** — Every email → AI analysis → decision → action is logged to Excel with timestamps for compliance.

6. **"Security first"** — PII Filtering activity redacts sensitive data before logging. UiPath AI Trust Layer ensures data is not retained by LLMs.

## Questions You Can Expect

- **Q: Why not use HTTP Request to call OpenAI directly?**
  **A:** GenAI Activities provide governed, secure AI access via UiPath's AI Trust Layer. No API keys to manage, no data privacy concerns, integrated error handling, and included in licensing.

- **Q: How do you handle AI hallucinations?**
  **A:** Confidence scoring from Sentiment Analysis gates auto-replies. Low confidence → human review via Action Center. We also validate Categorize output against the allowed category list.

- **Q: How would you scale to 10,000 emails/day?**
  **A:** Queue-based Dispatcher-Performer already supports multi-bot parallel processing. Set max concurrent performers to 5-10 via Queue Trigger. Orchestrator handles distribution.
