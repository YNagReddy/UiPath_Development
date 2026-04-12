# InsightMail — Email Classification Taxonomy

This document defines the 7 core categories used by the InsightMail AI agents to segregate and process incoming emails. These definitions are optimized to guide Generative AI models (via UiPath GenAI Activities) for consistent and accurate classification.

## 1 — Taxonomy Overview

| Category | Definition | Key Indicators | Strategy |
| :--- | :--- | :--- | :--- |
| **Complaint** | Customer expresses dissatisfaction or frustration with a product, service, or policy. | "disappointed", "wrong", "fix", "unacceptable" | Empathy + Resolution |
| **Request** | Customer asks for a specific action, change, or service to be performed. | "please send", "update my", "cancel", "I need" | Fulfillment / Auto-reply |
| **Inquiry** | Customer seeks information, clarification, or answers to questions. | "how to", "pricing", "what is", "information" | Information / FAQ |
| **Escalation** | Customer demands higher-level attention or formal intervention. | "manager", "legal", "second time", "unresolved" | Manager Review |
| **Info** | Customer provides information, updates, or files (FYI) without asking for action. | "for your info", "attached", "just letting you know" | Archive / Log |
| **Feedback** | Customer shares opinions, praise, or suggestions for improvement. | "great work", "suggestion", "opinion", "love it" | Acknowledge / Log |
| **Urgent** | Requires immediate attention due to time sensitivity or critical impact. | "asap", "emergency", "deadline", "critical" | High Priority |

---

## 2 — Detailed Agent Guidelines

### 2.1 — Complaint
*   **Goal**: Detect customer pain points and resolve friction.
*   **Agent Logic**: If sentiment is **Negative**, flag for empathetic response. If resolution is not obvious, escalate.
*   **Example**: *"The software crashed three times today and I lost my work. This is unacceptable."*

### 2.2 — Request
*   **Goal**: Automate repeatable service tasks.
*   **Agent Logic**: Extract entities (Invoice #, Date, Name) and verify if auto-fulfillment is possible.
*   **Example**: *"Can you please send a copy of my last three invoices to my accountant?"*

### 2.3 — Inquiry
*   **Goal**: Provide fast answers to common questions.
*   **Agent Logic**: Map the question to a knowledge base or summarize the query for a human.
*   **Example**: *"What are your opening hours during the holiday season?"*

### 2.4 — Escalation
*   **Goal**: Prevent churn and manage legal/reputational risk.
*   **Agent Logic**: **Always** route to Action Center for human oversight. Do not auto-reply.
*   **Example**: *"I have contacted you three times and still haven't received a refund. I am speaking to my lawyer tomorrow."*

### 2.5 — Info
*   **Goal**: Reduce clutter in the processing queue.
*   **Agent Logic**: Extact key details for logging but suppress reply generation.
*   **Example**: *"Just letting you know that the document we discussed is now uploaded to the portal."*

### 2.6 — Feedback
*   **Goal**: Gather business intelligence and customer sentiment.
*   **Agent Logic**: Sentiment analysis is critical here. Positive feedback should be logged for marketing.
*   **Example**: *"I really like the new dashboard layout, it's much more intuitive than the old one."*

### 2.7 — Urgent
*   **Goal**: Accelerate processing speed.
*   **Agent Logic**: Set `Priority` to **High** regardless of the other category.
*   **Example**: *"CRITICAL: Our production system is down and we need support immediately."*

---

## 3 — Technical Prompt Engineering (Template)

Use the following snippet in the **Categorize** or **Generate Content** activities for better results:

> "Classify the following email into exactly one of these categories: [Complaint, Request, Inquiry, Escalation, Info, Feedback, Urgent].
> 
> Definitions:
> - Complaint: Negative sentiment regarding product/service.
> - Request: Asking for an action or task completion.
> - Inquiry: Asking for information or clarification.
> - Escalation: Demanding management or legal attention.
> - Info: Sharing data/updates with no action required (FYI).
> - Feedback: General opinion or suggestions (Positive/Negative).
> - Urgent: Time-critical or business-stopping emergency.
> 
> Respond with only the category name."
