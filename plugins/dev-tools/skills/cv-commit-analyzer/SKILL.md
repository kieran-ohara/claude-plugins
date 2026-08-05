---
name: cv-commit-analyzer
description: Extract professional CV/resume accomplishments from a repository's git commit history. Analyses commits by author, groups them into projects, and transforms raw commits into polished, achievement-oriented bullet points. Use when the user wants to update their CV with recent work, prepare concrete project examples for an interview, or document what they have accomplished over a period.
allowed-tools: Bash, AskUserQuestion
---

# Analyse commit history into CV accomplishments

Study a user's git commit history and transform raw technical commits into
polished, achievement-oriented bullet points suitable for a CV or resume.
Approach it as an expert technical recruiter and CV writer would: emphasise
impact and outcomes, not activity.

## Core Methodology

1. **Commit Analysis Process**:
   - Ask the user which author to filter by (name or email) if not provided.
     Offer to detect it from `git config user.email` as a default.
   - Analyse commit messages, file changes, and patterns over time.
   - Group commits by project, feature area, or technology stack.
   - Identify significant contributions vs. routine maintenance.
   - Look for patterns indicating leadership, innovation, or problem-solving.

2. **Information Extraction**:
   - **Technologies Used**: Extract programming languages, frameworks, tools, and platforms.
   - **Project Scope**: Identify whether work was greenfield development, refactoring, feature additions, or bug fixes.
   - **Impact Indicators**: Look for commits related to performance improvements, new features, infrastructure changes, or architectural decisions.
   - **Collaboration Patterns**: Note contributions to shared libraries, code reviews, or cross-team initiatives.
   - **Time Investment**: Assess the duration and consistency of work on specific projects.

3. **CV Bullet Point Crafting**:
   Each bullet point should follow this structure:
   - Start with a strong action verb (Developed, Architected, Implemented, Optimized, Led, etc.).
   - Include specific technologies and tools used.
   - Quantify impact where possible (performance improvements, lines of code, number of features).
   - Focus on business value and outcomes, not just technical tasks.
   - Keep bullets concise (1-2 lines maximum).

## Output Format

Present the analysis in the following structure:

### Project: [Project Name]
**Duration**: [Timeframe based on commits]
**Technologies**: [List of technologies]

**Key Accomplishments**:
- [Bullet point 1]
- [Bullet point 2]
- [Bullet point 3]

---

Repeat for each distinct project or area of work.

## Quality Standards

- **Be Specific**: Avoid generic statements like "wrote code" - specify what was built and why it mattered.
- **Quantify When Possible**: Include metrics like "improved performance by X%", "reduced deployment time from X to Y", "implemented N features".
- **Use Professional Language**: Transform casual commit messages into polished professional statements.
- **Focus on Impact**: Emphasize outcomes and value delivered, not just activities performed.
- **Respect Confidentiality**: If commit messages contain sensitive information, generalize appropriately while maintaining the essence of the accomplishment.

## Git Commands to Use

Execute git commands to analyse the repository. Common commands include:
- `git log --author="[username]" --since="[date]" --pretty=format:"%h - %an, %ar : %s"` - Get commits by author
- `git log --author="[username]" --stat` - See file changes per commit
- `git log --author="[username]" --all --oneline --graph` - Visualize commit history
- `git shortlog -sn --author="[username]"` - Count commits by author

## Edge Cases and Clarifications

- If commit messages are unclear or too technical, infer intent from file changes and ask for clarification if needed.
- If the user has worked on multiple unrelated projects, organize accomplishments by project clearly.
- If commits span a very long time period, ask the user which timeframe they want to focus on.
- If commit messages are poorly written, focus on the actual code changes to understand the work done.
- When you encounter merge commits or automated commits, filter these out unless they represent significant integration work.

## Self-Verification Steps

Before presenting the analysis:
1. Ensure each bullet point is achievement-oriented, not task-oriented.
2. Verify that technologies mentioned are accurate based on file extensions and commit content.
3. Check that timeframes are realistic based on commit dates.
4. Confirm that the language is professional and free of jargon that non-technical recruiters wouldn't understand.
5. Validate that you've captured the most significant and impressive work, not just the most recent.

The goal is to help the user present their technical work in the most
compelling, professional way possible. Every bullet point should make a hiring
manager think "I want to interview this person."
