---
name: brainstorm
description: Explore requirements and approaches through collaborative dialogue before planning implementation
argument-hint: "[feature idea or problem to explore]"
---

# Brainstorm

Explore ideas and approaches through collaborative dialogue before implementation planning.

## Feature Description

<feature_description> $ARGUMENTS </feature_description>

**If empty, ask:** "What would you like to explore?"

## When to Use

- Requirements are unclear or ambiguous
- Multiple approaches could work
- Trade-offs need exploration
- You haven't fully articulated what you want

**Skip brainstorming when:** Requirements are explicit, you know exactly what you want, or it's a straightforward bug fix.

## Execution

### 1. Understand the idea

#### 1.1 Repository Search (Lightweight)

Check out the current project state first (files, docs, recent commits)

Focus on: similar features, established patterns, CLAUDE.md guidance.

#### 1.2 Collaborative Dialogue

Use **AskUserQuestion** to explore one question at a time. If a topic needs more exploration, break it into multiple questions.

**Good questions:**

- Multiple choice when natural options exist
- Start broad, then narrow
- Validate assumptions explicitly
- Ask about success criteria early

**Topics to cover:**
| Topic | Examples |
|-------|----------|
| Purpose | What problem does this solve? |
| Users | Who uses this? What's their context? |
| Constraints | Technical limitations? Dependencies? |
| Success | How will you know it's working? |
| Edge cases | What shouldn't happen? |

**Exit when:** The idea is clear OR the user says "proceed" or "let's move on"

### 2. Explore Approaches

Propose 2-3 different approaches based on research and conversation.

For each approach, provide:

- Brief description (2-3 sentences)
- Pros and cons
- When it's best suited

**Guidelines**:

- Present options conversationally with your reasoning
- Lead with your recommended option and explain why
- Be honest about trade-offs
- Consider YAGNI — simpler is usually better

### 3. Design Presentation

- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

### 4. Capture Design

Capture the design by writing to `.claude/brainstorms/YYYY-MM-DD-<topic>-brainstorm.local.md`:

```markdown
---
date: YYYY-MM-DD
topic: <kebab-case-topic>
---

# <Topic Title>

[Narrative summary of what we're building and why. Write it like you're explaining to someone who wasn't in the conversation.]

## Decisions (if any)

- [Decision]: [Rationale]

## Open Questions (if any)

- [Anything unresolved for planning phase]
```

Omit Decisions/Open Questions sections if there aren't any worth capturing.

### 6. Handoff

Use **AskUserQuestion**:

```md
**Question:** "What would you like to do next?"

**Options:**

1. **Keep exploring** - Continue the conversation
2. **Done for now** - Come back later (doc saved if captured)
```

## Resuming a Session

When resuming from a brainstorm doc:

1. Read the doc
2. Summarize: "Last time we decided [X]. Open questions were [Y]."
3. Ask: "Continue from here, or revisit any decisions?"

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Prefer simpler approaches
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense

NEVER CODE. Just explore and clarify.
