# Acadexa AI: Integrated Intelligent Features Documentation

This document provides a detailed overview of the AI-driven capabilities implemented within the **Acadexa** (Institutional Management System) project. The system leverages **Spring AI** with the **Google Gemini (Vertex AI)** LLM and **Firestore Vector Search** to provide a data-driven, intelligent experience for students, faculty, and administrators.

---

## 1. AI Chat & Intelligent Assistant (RAG System)
**Core Technology:** Retrieval-Augmented Generation (RAG) + Function Calling.

### **Capabilities:**
*   **Contextual Knowledge:** The assistant uses a `ManualFirestoreVectorStore` to search through institutional documents (PDFs, policies, handbooks) to provide accurate answers about campus rules, schedules, and procedures.
*   **Real-Time Database Actions:** Unlike standard chatbots, this assistant is "Actionable." It can trigger the following backend functions based on conversation:
    *   `createMenteeConcern`: Automatically logs a formal issue if a student mentions a problem.
    *   `createAnnouncement`: Drafts and posts announcements for authorized faculty.
    *   `createEvent`: Schedules and categorizes campus events via natural language.
*   **Deep Linking:** The AI can generate Markdown links that redirect users directly to specific screens within the Flutter application (e.g., `[View My Attendance](/RVU/student/attendance)`).

---

## 2. AI Placement & Career Engine
**Core Technology:** Apache Tika (Document Parsing) + Gemini 2.5 Pro/Flash.

### **Capabilities:**
*   **Resume Scoring & Feedback:** Analyzes uploaded PDF/Word resumes and provides a score (0-100) based on industry standards or specific job descriptions. It identifies missing keywords, formatting errors, and content strengths.
*   **Placement Readiness Predictor:** Analyzes a student's CGPA, skill set (from their profile), and backlog history to calculate their probability of securing a job in the current season.
*   **Skill Gap Analysis:** Compares a student's technical and soft skills against the requirements of a specific **Placement Drive** and recommends the top 3 learning resources to bridge the gap.
*   **Profile Match Report:** Generates a "Pros vs. Cons" report for a specific role, helping students understand if they are a good fit before they apply.

---

## 3. AI Educational & Success Insights
**Core Technology:** Multi-source Data Aggregation + LLM Analysis.

### **Capabilities:**
*   **Student Success Predictor:** Evaluates academic performance (Marks), attendance trends, and leave history to forecast future GPA and identify potential "sliding" performance early.
*   **At-Risk Identification:** Automatically flags students who are at risk of being detained (low attendance) or failing (poor internal marks) with personalized intervention suggestions.
*   **Leave Impact Forecaster:** When a student applies for a leave, the AI analyzes their current attendance and upcoming exam schedule to warn them if the leave will push them below the required attendance threshold.

---

## 4. AI Communication & Content Summarization
**Core Technology:** Text Summarization & Personalization.

### **Capabilities:**
*   **Announcement Summarizer:** Automatically condenses long, multi-paragraph institutional notices into two concise sentences, allowing students to stay informed quickly.
*   **Personalized Event Recommendations:** Matches upcoming campus events (workshops, hackathons, sports) with a student's academic program and interests.
*   **Relevance Explanation:** For every recommended event, the AI provides a 1-sentence personalized reason *why* the student should attend (e.g., "As a CS student, this Cloud Workshop will help you with your upcoming Semester 6 project").

---

## 5. AI Feedback & Administrative Analytics
**Core Technology:** Sentiment Analysis & Structured Data Generation.

### **Capabilities:**
*   **Sentiment & Theme Analysis:** Analyzes hundreds of responses from Custom Forms (e.g., Course Feedback) to determine the overall "mood" (Positive/Negative) and identifies the top 3 recurring themes/complaints.
*   **Actionable Admin Insights:** Provides administrators with 3 concrete, data-driven steps they can take to improve institutional quality based on feedback data.
*   **Smart Form Proposer:** Admins can simply type a topic (e.g., "Library Feedback"), and the AI generates a complete JSON schema for a professional form, including field types (Multiple Choice, Text, etc.) and suggested labels.

---

## 6. AI System & IT Diagnostics
**Core Technology:** Technical Log Analysis.

### **Capabilities:**
*   **Bug Analyzer (The "IT Auditor"):** Translates complex, technical Java/Flutter stack traces into:
    1.  A **Simple Summary** for non-technical administrators (using analogies).
    2.  A **Technical Deep-Dive** for developers, identifying the exact file and line number of the failure with suggested code fixes.
*   **Security & Access Audit:** Analyzes faculty and staff attendance/login logs to detect anomalies like "Impossible Travel" (logins from two far locations in a short time) or unusual access hours.

---

## Technical Architecture Overview
*   **Backend:** Spring Boot (Java 21)
*   **AI Framework:** Spring AI (Milestone 6)
*   **LLM Provider:** Google Gemini via Vertex AI
*   **Vector DB:** Google Firestore (Native Vector Search)
*   **Document Parsing:** Apache Tika
*   **Frontend:** Flutter (Mobile & Web compatible)
