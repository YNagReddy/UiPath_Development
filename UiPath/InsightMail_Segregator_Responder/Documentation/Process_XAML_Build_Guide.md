# Process.xaml — Step-by-Step Build Guide

> Open `Framework/Process.xaml` in UiPath Studio and follow these steps exactly.
> The existing Process.xaml should already have a Try-Catch inside a Sequence.
> Build everything INSIDE the Try block.

---

## STEP 0: Create Variables

Before adding any activities, create ALL variables in the Variables panel:

| Variable Name       | Type            | Scope         | Default      |
|---------------------|-----------------|---------------|--------------|
| str_Subject         | String          | Process       | ""           |
| str_Sender          | String          | Process       | ""           |
| str_Body            | String          | Process       | ""           |
| str_ReceivedDate    | String          | Process       | ""           |
| str_Category        | String          | Process       | ""           |
| dbl_CatConfidence   | Double          | Process       | 0.0          |
| str_Sentiment       | String          | Process       | ""           |
| dbl_SentConfidence  | Double          | Process       | 0.0          |
| str_Summary         | String          | Process       | ""           |
| str_Entities        | String          | Process       | ""           |
| str_Priority        | String          | Process       | ""           |
| str_ReplyText       | String          | Process       | ""           |
| str_CleanBody       | String          | Process       | ""           |
| str_ActionTaken     | String          | Process       | ""           |
| str_ReplySent       | String          | Process       | "No"         |
| str_ProcessingLog   | String          | Process       | ""           |
| dbl_ConfThreshold   | Double          | Process       | 0.80         |

---

## STEP 1: Extract Queue Item Fields

> Purpose: Pull the email data out of the QueueItem into working variables.

**Activity**: 4x `Assign` activities (inside a Sequence named "Extract Queue Item Fields")

```
Assign 1:  str_Subject      = in_TransactionItem.SpecificContent("Subject").ToString
Assign 2:  str_Sender       = in_TransactionItem.SpecificContent("Sender").ToString
Assign 3:  str_Body         = in_TransactionItem.SpecificContent("Body").ToString
Assign 4:  str_ReceivedDate = in_TransactionItem.SpecificContent("ReceivedDate").ToString
```

**Then add (Body Truncation)**:

```
Assign 5:  str_Body = If(str_Body.Length > 4000, str_Body.Substring(0, 4000), str_Body)
```

> This prevents GenAI token overflow. 4000 chars is the safe limit.

**Add a Log Message** after:
```
Log Message (Info): "Processing email from: " + str_Sender + " | Subject: " + str_Subject
```

---

## STEP 2: Categorize Email

> **Activity**: `Categorize` (from UiPath.GenAI.Activities)
> Find it in Activities panel → search "Categorize"

**Properties**:
| Property         | Value                                                                 |
|------------------|-----------------------------------------------------------------------|
| Input Text       | str_Subject + ". " + str_Body                                        |
| Categories       | {"Complaint", "Request", "Inquiry", "Escalation", "Info", "Feedback", "Urgent"} |
| ModelName        | "gpt-4o-mini" (or leave default for AI Trust Layer auto-selection)    |
| Output Category  | str_Category                                                         |
| Output Confidence| dbl_CatConfidence                                                    |

> **How to set Categories**: In the Properties panel, click the `...` button next to Categories.
> Add each category as a separate string in the collection editor:
> Complaint, Request, Inquiry, Escalation, Info, Feedback, Urgent

**Add Log Message**:
```
Log Message (Info): "Category: " + str_Category + " (Confidence: " + dbl_CatConfidence.ToString("F2") + ")"
```

---

## STEP 3: Sentiment Analysis

> **Activity**: `Analyze Sentiment` (from UiPath.GenAI.Activities)
> Search "Sentiment" in Activities panel

**Properties**:
| Property          | Value                              |
|-------------------|------------------------------------|
| Input Text        | str_Body                           |
| Output Sentiment  | str_Sentiment                      |
| Output Confidence | dbl_SentConfidence                 |

> Output Sentiment will be: "Positive", "Negative", or "Neutral"

**Add Log Message**:
```
Log Message (Info): "Sentiment: " + str_Sentiment + " (Confidence: " + dbl_SentConfidence.ToString("F2") + ")"
```

---

## STEP 4: Summarize Email

> **Activity**: `Summarize Text` (from UiPath.GenAI.Activities)
> Search "Summarize" in Activities panel

**Properties**:
| Property      | Value                                                    |
|---------------|----------------------------------------------------------|
| Input Text    | str_Body                                                 |
| Prompt/Instructions | "Summarize this email in 50-75 words. Focus on the main issue, any action required, and key details like dates, amounts, and reference numbers." |
| Output Summary| str_Summary                                              |

**Add Log Message**:
```
Log Message (Info): "Summary: " + str_Summary
```

---

## STEP 5: Named Entity Recognition (NER)

> **Activity**: `Extract Named Entities` (from UiPath.GenAI.Activities)
> Search "Named Entity" or "NER" in Activities panel

**Properties**:
| Property        | Value                |
|-----------------|----------------------|
| Input Text      | str_Body             |
| Output Entities | str_Entities         |

> Output will be a JSON string with extracted persons, organizations, dates, amounts, references.

**Add Log Message**:
```
Log Message (Info): "Entities: " + str_Entities
```

---

## STEP 6: Priority Assessment

> **Activity**: `Content Generation` (from UiPath.GenAI.Activities)
> Search "Content Generation" or "Generate Content" in Activities panel
> We use Content Generation here because there's no dedicated "Priority" activity.

**Properties**:
| Property     | Value                                                              |
|--------------|--------------------------------------------------------------------|
| Prompt       | See prompt below                                                   |
| Output       | str_Priority                                                       |

**Prompt** (paste this exactly):
```
Analyze this email and classify its priority as exactly one of: High, Medium, Low.

Rules:
- High: Complaints with financial impact, escalations, legal issues, system outages, urgent safety
- Medium: Standard requests, inquiries, follow-ups needing action within days
- Low: Informational, positive feedback, thank-you notes, newsletters

Email Category: {str_Category}
Email Sentiment: {str_Sentiment}
Email Subject: {str_Subject}
Email Body: {str_Body}

Respond with ONLY one word: High, Medium, or Low.
```

> **IMPORTANT**: In UiPath, you build this prompt string using concatenation:
> ```
> "Analyze this email and classify its priority as exactly one of: High, Medium, Low." + vbCrLf + vbCrLf + "Rules:" + vbCrLf + "- High: Complaints with financial impact, escalations, legal issues, system outages, urgent safety" + vbCrLf + "- Medium: Standard requests, inquiries, follow-ups needing action within days" + vbCrLf + "- Low: Informational, positive feedback, thank-you notes, newsletters" + vbCrLf + vbCrLf + "Email Category: " + str_Category + vbCrLf + "Email Sentiment: " + str_Sentiment + vbCrLf + "Email Subject: " + str_Subject + vbCrLf + "Email Body: " + str_Body + vbCrLf + vbCrLf + "Respond with ONLY one word: High, Medium, or Low."
> ```

**Add cleanup Assign**:
```
Assign: str_Priority = str_Priority.Trim.Split(vbCrLf.ToCharArray)(0).Trim
```
> This extracts just "High", "Medium", or "Low" even if the AI adds extra text.

**Add Log Message**:
```
Log Message (Info): "Priority: " + str_Priority
```

---

## STEP 7: Generate Reply

> **Activity**: `Generate Email` (from UiPath.GenAI.Activities)
> Search "Generate Email" in Activities panel

**Properties**:
| Property       | Value                                                          |
|----------------|----------------------------------------------------------------|
| Context/Prompt | See prompt below                                               |
| Output Email   | str_ReplyText                                                  |

**Prompt**:
```
"Generate a professional reply to this email." + vbCrLf + "Category: " + str_Category + vbCrLf + "Sentiment: " + str_Sentiment + vbCrLf + "Original Subject: " + str_Subject + vbCrLf + "Original Body: " + str_Body + vbCrLf + vbCrLf + "Rules:" + vbCrLf + "- Match the formality of the original email" + vbCrLf + "- If Complaint/Escalation: be empathetic, apologize, promise investigation" + vbCrLf + "- If Request: confirm receipt and provide next steps" + vbCrLf + "- If Inquiry: provide helpful, accurate information" + vbCrLf + "- Keep the reply under 150 words" + vbCrLf + "- Sign off as 'InsightMail Support Team'"
```

**Add Log Message**:
```
Log Message (Info): "Reply generated (" + str_ReplyText.Length.ToString + " chars)"
```

---

## STEP 8: PII Filtering

> **Activity**: `PII Filtering` or `Detect PII` (from UiPath.GenAI.Activities)
> Search "PII" in Activities panel
> This redacts sensitive data BEFORE we log to Excel.

**Properties**:
| Property      | Value                    |
|---------------|--------------------------|
| Input Text    | str_Body                 |
| Output        | str_CleanBody            |

> The activity automatically detects and redacts: SSN, credit cards, phone numbers, etc.

**Add Log Message**:
```
Log Message (Info): "PII filtering complete. Clean body length: " + str_CleanBody.Length.ToString
```

---

## STEP 9: Decision Logic — Route the Email

> **Activity**: `If` (nested)
> This is the decision engine that determines what action to take.

### Outer If — Check for Escalation
```
Condition: str_Category = "Escalation" OrElse str_Category = "Complaint" OrElse str_Category = "Urgent" OrElse str_Priority = "High"
```

**Then (Escalation Path)**:
```
Sequence: "Escalate to Action Center"
  Assign: str_ActionTaken = "Escalated"
  Assign: str_ReplySent = "No"
  Log Message (Warn): "ESCALATED: " + str_Subject + " | Category: " + str_Category + " | Priority: " + str_Priority

  ' OPTIONAL: Create Task activity for Action Center
  ' Activity: Create Form Task (UiPath.Persistence.Activities)
  ' Title: "[InsightMail] " + str_Category + ": " + str_Subject
  ' Data: str_Summary + vbCrLf + "Suggested Reply: " + str_ReplyText
```

**Else → Inner If — Check for Auto-Reply**:
```
Condition: (str_Category = "Request" OrElse str_Category = "Inquiry") AndAlso dbl_CatConfidence >= dbl_ConfThreshold
```

**Then (Auto-Reply Path)**:
```
Sequence: "Send Auto-Reply"
  Assign: str_ActionTaken = "Auto-replied"
  Assign: str_ReplySent = "Yes"
  Log Message (Info): "AUTO-REPLY: Sending reply to " + str_Sender
  
  ' FOR NOW: Just log. Add Send Mail in Phase 3.
  ' Activity: Send Outlook Mail Message
  ' To: str_Sender 
  ' Subject: "Re: " + str_Subject
  ' Body: str_ReplyText
```

**Else (Log Only Path)**:
```
Sequence: "Log Only"
  Assign: str_ActionTaken = "Logged"
  Assign: str_ReplySent = "No"
  Log Message (Info): "LOGGED ONLY: " + str_Category + " email from " + str_Sender
```

---

## STEP 10: Write to Excel Log

> **Activity**: `Append Range` (from UiPath.Excel.Activities)
> This writes the processed email data to the audit trail.

**First, build a DataTable row**:

Use `Build Data Table` activity:
- Name output variable: dt_LogRow
- Columns: Timestamp, Sender, Subject, Category, Priority, Sentiment, Sentiment_Score, Summary, Entities, Reply_Text, Reply_Sent, Action_Taken, Status

Then use `Add Data Row`:
```
ArrayRow: {
  Now.ToString("yyyy-MM-dd HH:mm:ss"),
  str_Sender,
  str_Subject,
  str_Category,
  str_Priority,
  str_Sentiment,
  dbl_SentConfidence.ToString("F2"),
  str_Summary,
  str_Entities,
  str_ReplyText,
  str_ReplySent,
  str_ActionTaken,
  "Success"
}
DataTable: dt_LogRow
```

Then `Append Range`:
```
WorkbookPath: "Data\Output\EmailProcessingLog.xlsx"
SheetName: "ProcessingLog"
DataTable: dt_LogRow
```

> **SIMPLER ALTERNATIVE**: If you prefer, use `Write Cell` or `Write Range` with a counter.
> But `Append Range` is cleanest for adding one row at a time.

**Add final Log Message**:
```
Log Message (Info): "✓ Email processed successfully: [" + str_Category + "] " + str_Subject + " → " + str_ActionTaken
```

---

## COMPLETE ACTIVITY SEQUENCE (Visual Summary)

```
Process.xaml
└── Try
    ├── [Sequence] Extract Queue Item Fields
    │   ├── Assign: str_Subject
    │   ├── Assign: str_Sender
    │   ├── Assign: str_Body
    │   ├── Assign: str_ReceivedDate
    │   ├── Assign: str_Body (truncate)
    │   └── Log Message
    │
    ├── [Categorize] → str_Category, dbl_CatConfidence
    ├── Log Message
    │
    ├── [Analyze Sentiment] → str_Sentiment, dbl_SentConfidence
    ├── Log Message
    │
    ├── [Summarize Text] → str_Summary
    ├── Log Message
    │
    ├── [Extract Named Entities] → str_Entities
    ├── Log Message
    │
    ├── [Content Generation] Priority → str_Priority
    ├── Assign: str_Priority cleanup
    ├── Log Message
    │
    ├── [Generate Email] → str_ReplyText
    ├── Log Message
    │
    ├── [PII Filtering] → str_CleanBody
    ├── Log Message
    │
    ├── [If] Escalation?
    │   ├── Then: Assign str_ActionTaken = "Escalated"
    │   └── Else: [If] Auto-Reply?
    │       ├── Then: Assign str_ActionTaken = "Auto-replied"
    │       └── Else: Assign str_ActionTaken = "Logged"
    │
    ├── [Build Data Table] → dt_LogRow
    ├── [Add Data Row]
    ├── [Append Range] → EmailProcessingLog.xlsx
    └── Log Message (final)

└── Catch
    ├── BusinessRuleException → SetTransactionStatus = Failed (Business)
    └── System.Exception → SetTransactionStatus = Failed (Application)
```

---

## TESTING CHECKLIST

After building, test with a manual queue item in Orchestrator:

```json
Queue: InsightMail_Emails
Reference: "TEST-COMP-001"
Content:
{
  "Subject": "URGENT: Multiple charges on my account!",
  "Sender": "michael.scott@test.com",
  "Body": "I am extremely frustrated. I just checked my credit card statement and I see three identical charges of $149.99 from your company on April 10th. My invoice number is INV-83742. This is completely unacceptable.",
  "ReceivedDate": "2026-04-12"
}
```

**Expected output**:
- Category: Complaint
- Sentiment: Negative
- Priority: High
- Action: Escalated
- Reply Sent: No
- Excel log row written

---

## TIPS

1. **Build incrementally**: Add Step 1-2 first, run, verify. Then add 3-4, run, verify. Don't build all 10 steps before testing.
2. **Use breakpoints**: Set a breakpoint after each GenAI activity to inspect outputs.
3. **GenAI may take 2-5 seconds per call**: 8 activities × ~3 sec = ~24 sec per email. This is normal.
4. **If a GenAI activity fails**: Check Integration Service connection in Automation Cloud.
5. **Save frequently**: Ctrl+S after each step. Studio can crash.
