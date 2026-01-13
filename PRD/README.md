# Product Requirements Documents (PRDs)

This folder contains all PRDs for the "Are You Dead Yet?" project.

## PRD Process

### When to Create a PRD

Create a new PRD before starting work on:
- New features or feature sets
- Major changes to existing functionality
- Architectural changes
- User-facing workflow changes

### PRD Naming Convention

```
PRD-XXX-short-description.md
```

- `XXX` = Sequential number (001, 002, 003...)
- `short-description` = Kebab-case feature name

### PRD Template

Each PRD should include:

1. **Overview** - Problem, solution, target users
2. **Goals & Success Metrics** - What success looks like
3. **Features** - Prioritized list (P0/P1/P2)
4. **Technical Architecture** - How it will be built
5. **User Flows** - Step-by-step journeys
6. **Design Decisions** - Why we made certain choices
7. **Known Limitations** - What's out of scope
8. **Future Considerations** - What might come next

### Status Values

| Status | Meaning |
|--------|---------|
| Draft | Work in progress, not ready for review |
| In Review | Ready for stakeholder feedback |
| Approved | Ready for implementation |
| In Progress | Currently being built |
| Completed | Shipped to production |
| Deprecated | No longer relevant |

---

## PRD Index

| PRD | Title | Status | Description |
|-----|-------|--------|-------------|
| [PRD-001](./PRD-001-initial-mvp.md) | Initial MVP | Completed | Core dead man's switch functionality |

---

## Contributing

1. Copy the template structure from an existing PRD
2. Fill in all sections
3. Set status to "Draft"
4. Request review before implementation
5. Update status as work progresses
