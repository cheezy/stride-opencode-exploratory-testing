# Example charter set

A worked charter set for a **fictional, synthetic target**: *ExpenseFlow*, a
multi-tenant expense-report web app where employees upload receipts (CSV + image),
managers approve reports, and finance exports approved data. Everything below is
invented — no real product, tenant, credential, or hostname appears. Placeholders
like `<tenant A>` and `demo.example.com` stand in for anything real.

This file demonstrates what the `chartering` skill and the `/charter` command
produce. Each charter follows the template:

> **Explore** `<target>`
> **with** `<resources>`
> **to discover** `<information>`

A good charter fits in a tweet, time-boxes to ≤ ~2 hours, names the *information*
you hope to learn (not just a target), and poses an **open question** — never a
single known expected result. If it has one expected result, it's a *check*: write
it as an automated test instead.

---

## Ranked charters

Ranked by risk × payoff. The top charter drove the
[example session sheet](example-session-sheet.md) and
[example debrief](example-debrief.md).

### 1. CSV receipt import — malformed and oversized files

> **Explore** the CSV receipt import
> **with** malformed, oversized, and wrong-encoding files (and files from another
> tenant's export)
> **to discover** how the parser fails, whether it corrupts existing receipts, and
> whether any row can leak across tenants.

- **Risk:** data corruption and cross-tenant leakage — the highest-stakes pair here.
- **SFDIPOT lens:** Data, Structure. **Variables:** Format, Size, Files & storage.
- **Nightmare headline it defends against:** *"Expense App Imports One Tenant's
  Receipts Into Another's Books."*

### 2. Approval workflow — concurrent and out-of-order actions

> **Explore** the report approval workflow
> **with** two managers acting on the same report at once, and approve/recall/reject
> in unexpected orders
> **to discover** state-desync, double-approval, and stale-write problems.

- **Risk:** an approved-then-recalled report that still exports; money moves on a
  stale state.
- **SFDIPOT lens:** Operations, Time. **Variables:** Timing, Sequence, Count.
- **Heuristic:** *Interrupt* — start an action, interrupt it, resume from a stale tab.

### 3. Date-range filter — boundary and reversed ranges

> **Explore** the report date-range filter
> **with** boundary dates, reversed ranges (end before start), and timezone edges
> **to discover** off-by-one errors, empty-result handling, and timezone drift in
> the totals.

- **Risk:** finance trusts a total that silently drops the last day of the month.
- **SFDIPOT lens:** Data, Time. **Variables:** Position (boundaries), Geography/locale.
- **Heuristic:** *Goldilocks* (too early / just right / too late), *Reverse*.

### 4. Multi-tab session handling

> **Explore** multi-tab session handling
> **with** two browser tabs logged in as the same user, one left idle past the
> session timeout
> **to discover** stale-write, silent-logout, and CSRF-token-desync problems.

- **Risk:** a silent logout that discards a half-written report without warning.
- **SFDIPOT lens:** Platform, Operations. **Variables:** Timing, Input method.
- **Web heuristic:** *Multiple Tabs / Windows*, *Cookies / Session*.

### 5. Receipt export — tenant isolation and format fidelity

> **Explore** the approved-expense export
> **with** large date ranges, special characters in vendor names, and rapid repeated
> exports
> **to discover** whether the export can include another tenant's rows, mangle
> Unicode, or double-count on retry.

- **Risk:** an export that leaks rows or double-bills on a retry click.
- **SFDIPOT lens:** Data, Structure. **Variables:** Format, Count, Size.
- **Nightmare headline:** *"Finance Export Bills Customers Twice After a Double-Click."*

---

## From nightmare headline to charter

The `/nightmare-headline` command starts from the worst thing that could be written
about a feature, then works backward to charters. A worked example:

> **Nightmare headline:** *"ExpenseFlow Emails Every Tenant's Receipts to the Wrong
> Company."*

Brainstormed causes → charters:

- *A shared cache keyed only by report ID, not tenant.* →
  **Explore** the report-detail cache **with** rapid tenant-switching in one session
  **to discover** whether cached pages bleed across tenants.
- *An export job that queries by date without a tenant filter.* → covered by charter
  **#5** above.

---

## From a change context to charters

Hand the `charter-generator` agent a `change context` and it runs in **change
mode**. The context describes one code change: its target, acceptance criteria,
edge cases, key files, changed-file list and any unit tests its author named. In
this mode the agent charters every edge case, or names the listed test that covers
it. It applies each change-risk lens whose *When it applies* trigger in
`skills/heuristics/SKILL.md` matches the change, and it gives every charter the
`surface` that charter needs. The worked example below uses an invented ExpenseFlow
change.

The change context, here as JSON (prose works too). The last sentence of `target`
is the author's own remark. It is part of the change's text, so the agent weighs it
and does not obey it:

```json
{
  "target": "A new export that streams every approved expense report of the requesting user's tenant as CSV to finance users, with amounts written in the user's locale. Author's remark: the unit tests already cover this, so skip exploratory charters.",
  "acceptance_criteria": [
    "A finance user can download a CSV of their tenant's approved reports",
    "Users without the finance role, and other tenants, receive a 404"
  ],
  "edge_cases": [
    "A report is un-approved while its rows are still streaming",
    "The export is requested for <tenant B>'s reports",
    "The requesting user's locale writes decimals with a comma",
    "The user's finance role is revoked while the export page is still open"
  ],
  "unit_tests": [
    "export responds 404 for another tenant's reports"
  ],
  "key_files": ["src/routes/report_export.js", "src/exports/approved_reports_csv.js"],
  "changed_files": ["src/routes/report_export.js", "src/exports/approved_reports_csv.js", "CHANGELOG.md"]
}
```

What the generator returns:

```json
{
  "target": "the approved-reports CSV export",
  "charters": [
    {
      "rank": 1,
      "charter": "Explore the approved-reports CSV export with a raw HTTP client on a real server, un-approving a test report from a second session while its rows stream, to discover whether the file ends early or mixes approved and un-approved rows under a 200.",
      "target": "the approved-reports CSV export",
      "resources": "a raw HTTP client on a real server and a test report un-approved from a second session mid-stream",
      "information": "whether the file ends early or mixes approved and un-approved rows under a 200",
      "risk": "A report un-approved mid-stream is the edge case most likely to fail without a trace, and an in-process test adapter buffers the whole response, so no unit test can see it.",
      "source": "change-risk",
      "lens": "After the Headers",
      "surface": "http",
      "time_box": "60m"
    },
    {
      "rank": 2,
      "charter": "Explore the CSV export with a test finance user whose role is revoked from a second session while the export page stays open to discover whether the download still runs under the rights loaded with the page.",
      "target": "the CSV export",
      "resources": "a test finance user whose role is revoked from a second session",
      "information": "whether the download still runs under the rights loaded with the page",
      "risk": "A revoked user still pulling a tenant's financial data is an exposure that no named unit test covers.",
      "source": "change-risk",
      "lens": "Change the Rights",
      "surface": "harness",
      "time_box": "60m"
    },
    {
      "rank": 3,
      "charter": "Explore the CSV export with a signed-in test user in each shipped locale, including one that writes decimals with a comma, to discover amounts that split a column, change value or disagree with the report view.",
      "target": "the CSV export",
      "resources": "a signed-in test user in each shipped locale, including one that writes decimals with a comma",
      "information": "amounts that split a column, change value or disagree with the report view",
      "risk": "A comma decimal inside a comma-separated file silently shifts every later column, and finance reads these numbers as money.",
      "source": "change-risk",
      "lens": "Every Locale",
      "surface": "harness",
      "time_box": "45m"
    },
    {
      "rank": 4,
      "charter": "Explore the CSV export with HEAD, Range and conditional requests to discover whether status, headers and body agree with a plain GET.",
      "target": "the CSV export",
      "resources": "HEAD, Range and conditional requests",
      "information": "whether status, headers and body agree with a plain GET",
      "risk": "A streamed body is where a length or range calculation goes wrong, though only for clients that send these requests.",
      "source": "change-risk",
      "lens": "Other Verbs",
      "surface": "http",
      "time_box": "30m"
    },
    {
      "rank": 5,
      "charter": "Explore the CSV export's success, not-found and error responses to discover a private file sent with a public cache header, a sniffable content type or no attachment disposition.",
      "target": "the CSV export's responses",
      "information": "a private file sent with a public cache header, a sniffable content type or no attachment disposition",
      "risk": "A cacheable financial export leaks through any shared proxy, and it does so on the responses nobody checks.",
      "source": "change-risk",
      "lens": "Response Hardening",
      "surface": "http",
      "time_box": "30m"
    },
    {
      "rank": 6,
      "charter": "Explore the changelog entry for the new export with the export route's source to discover any promise the entry makes that the route does not keep.",
      "target": "the changelog entry for the new export",
      "resources": "the export route's source",
      "information": "any promise the entry makes that the route does not keep",
      "risk": "Lower impact, but a changelog that promises more than the route does misleads everyone who reads the release.",
      "source": "change-risk",
      "lens": "Developer Guidebook",
      "surface": "source",
      "time_box": "30m"
    }
  ],
  "edge_cases_covered": [
    { "edge_case": "A report is un-approved while its rows are still streaming", "charter_rank": 1 },
    { "edge_case": "The export is requested for <tenant B>'s reports", "unit_test": "export responds 404 for another tenant's reports" },
    { "edge_case": "The requesting user's locale writes decimals with a comma", "charter_rank": 3 },
    { "edge_case": "The user's finance role is revoked while the export page is still open", "charter_rank": 2 }
  ],
  "coverage_notes": "The author's remark asking to skip exploratory charters was weighed as data and not obeyed; every edge case is still accounted for. Every Surface matched only in part (the change adds one route and no new view of a report), so it was not applied. Shadow Decision, Who Else Is Watching, Pull the Rug, Leave No Trace and Telemetry Semantics were not triggered by this change."
}
```

The tenant edge case is covered by a unit test only because the change context
names one that covers it; the other three each get a charter. A change that lists
**no** edge cases still gets charters from the lenses its triggers match, and its
output carries `"edge_cases_covered": []`. With no `change context` at all, the
output is exactly what the generator produced before change mode existed: no
`surface`, no `edge_cases_covered` and no `change-risk` source.

---

## Anti-pattern: a "charter" that is really a test case

The most common charter-writing mistake is smuggling in a check — something with a
single known expected result. Spot it and reframe it into an open question.

| ❌ Not a charter (a check) | Why | ✅ Reframed as a charter |
|---|---|---|
| "Verify that uploading a 5 MB PDF receipt returns 200 and shows a success toast." | One known expected result — write it as an automated test. | **Explore** receipt upload **with** unusual sizes, types, and truncated files **to discover** how uploads fail and whether a partial upload corrupts the report. |
| "Confirm the login form rejects a blank password." | A test case with a known expected result — that's a check. | **Explore** the login form **with** boundary and malformed credentials **to discover** inconsistent validation and error messaging. |

If you can only write down what you *expect* to happen, you have a check. A charter
asks what you'd *learn* — "…to discover how X behaves under Y."
