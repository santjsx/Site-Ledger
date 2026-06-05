# SITE VOICE LEDGER - PRODUCT REQUIREMENTS DOCUMENT

## PRODUCT OVERVIEW

Site Voice Ledger is a voice-first mobile application for construction supervisors who currently maintain daily site records in a physical notebook.

The application allows users to manage multiple construction sites and create daily entries entirely through Telugu voice input.

The product is designed specifically for users with low digital literacy who prefer speaking over typing.

The application must feel dramatically simpler and faster than maintaining a notebook.

---

# PROBLEM STATEMENT

Construction supervisors currently record daily site information manually in notebooks.

This creates several problems:

* Data is difficult to search
* Records can be lost
* Calculations are manual
* Historical entries are hard to review
* Daily bookkeeping consumes time

Most existing construction management software is overly complex and unsuitable for field workers.

The goal is to create the simplest possible digital replacement for a notebook.

---

# PRODUCT VISION

If WhatsApp Voice Messages and Apple Notes had a child specifically designed for construction supervisors, it would look like this product.

The microphone is the primary interface.

Typing is a fallback.

Voice is the default.

---

# TARGET USER

Primary User:

Construction Supervisor / Small Contractor

Characteristics:

* Reads Telugu only
* Limited English knowledge
* Limited technical knowledge
* Uses Android phone
* Works outdoors
* Wants speed
* Hates complex software
* Already maintains physical notebooks

---

# CORE PRODUCT PHILOSOPHY

The product should answer only four questions:

1. Which site?
2. How many labourers worked?
3. How much money was received?
4. How much money was paid?

Everything else is secondary.

---

# NON-GOALS

The application is NOT:

* ERP software
* Construction management software
* Inventory software
* Payroll software
* Attendance software
* Accounting software
* CRM software

Do not build these features.

---

# CORE ENTITIES

## Site

Fields:

* id
* siteName
* ownerName
* createdAt
* updatedAt

---

## Daily Entry

Fields:

* id
* siteId
* date
* labourCount
* ownerAmount
* labourPaid
* note
* voiceTranscript
* createdAt
* updatedAt

---

# PRIMARY USER FLOW

User opens app

↓

Selects site

↓

Taps microphone

↓

Speaks naturally in Telugu

↓

AI extracts information

↓

User reviews extraction

↓

User saves

↓

Entry stored

Target completion time:

Less than 20 seconds

---

# VOICE INPUT REQUIREMENTS

The system must support natural Telugu speech.

User should never be forced to follow a strict format.

Example Inputs:

"ఈ రోజు 12 మంది పని చేశారు"

"ఓనర్ 25000 ఇచ్చాడు"

"కూలీలకి 8400 ఇచ్చాను"

"స్లాబ్ పని పూర్తయింది"

The system must extract:

Labour Count

Owner Amount

Labour Paid

Note

---

# VOICE PROCESSING PIPELINE

Audio

↓

Speech-to-Text

↓

Text Parsing

↓

Structured Data

↓

Review Screen

↓

Save

---

# REQUIRED SCREENS

## Splash Screen

Minimal

Brand

Fast loading

---

## Home Screen

Displays:

Active Sites

Recent Sites

Quick Add Entry

Today's Activity

Primary CTA:

Record Entry

---

## Sites Screen

Displays:

All Sites

Search

Add Site

Site Balance

Last Entry Date

---

## Add Site Screen

Voice-first site creation

Manual entry fallback

Fields:

Site Name

Owner Name

---

## Site Details Screen

Displays:

Site Name

Owner Name

Total Received

Total Paid

Current Balance

Entry Timeline

Primary Action:

Record New Entry

---

## Voice Recording Screen

Most important screen in product.

Large microphone button.

Minimal distractions.

Displays:

Listening State

Recording State

Processing State

---

## AI Review Screen

Displays extracted information.

Fields:

Labour Count

Owner Amount

Labour Paid

Note

Every field editable.

---

## Edit Entry Screen

Allows correction after AI extraction.

Supports:

Voice correction

Manual correction

---

## Entry Timeline Screen

Chronological entries.

Latest first.

Simple cards.

No tables.

---

## Settings Screen

Language

Backup Status

App Information

---

# DESIGN PRINCIPLES

One screen = one task.

One primary action per screen.

Maximum readability.

Large typography.

Large touch targets.

Minimal cognitive load.

No clutter.

No unnecessary navigation.

No dense dashboards.

No complex forms.

---

# VISUAL DESIGN SYSTEM

Style:

Premium

Minimal

Modern

Calm

Trustworthy

Consumer-grade

Not enterprise software

Not ERP

Not accounting software

Inspired by:

Apple Notes

Linear

Notion

Airbnb

---

# TYPOGRAPHY

Primary:

Noto Sans Telugu

Large typography.

High readability.

Designed for outdoor visibility.

---

# ACCESSIBILITY

High contrast

Large tap targets

Outdoor visibility

One-handed operation

Low digital literacy support

Voice-first interactions

---

# SUCCESS METRICS

Daily entry creation under 20 seconds.

Less than 3 taps before recording.

Less than 1 minute training required.

User able to operate app without typing.

95% of daily entries created through voice.

---

# TECH STACK

Frontend:
Flutter

Backend:
Firebase

Database:
Cloud Firestore

Storage:
Firebase Storage

Authentication:
Firebase Authentication

Voice:
Whisper or Android Speech Recognition

State Management:
Riverpod

Architecture:
Feature First Clean Architecture

Offline Support:
Required

Automatic Sync:
Required

---

# VERSION 1 SCOPE

Build only:

* Authentication
* Sites
* Voice Recording
* AI Extraction
* Entry Review
* Edit Entry
* Timeline
* Settings

Do not build anything else.

Every feature added must be justified by helping the user record daily site information faster than a physical notebook.
