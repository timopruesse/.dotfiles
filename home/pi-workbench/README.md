# pi-workbench

> Retired from the active dotfiles workflow in favor of full `pi-pstack` Poteto
> Mode. Provisioning removes this package registration but preserves its source
> and private saved contracts. The pi-subagents integration below is historical;
> do not reinstall it alongside pstack without explicitly revisiting the design.

A private local Pi package: verification contracts, thin-context native handoffs,
and **explicit Herdr visibility/navigation**. No Agent Fleet dependency, new
subagent runtime, system-prompt replacement, automatic delegation, or pane workers.

## Install

The dotfiles `home/` provisioning links this directory to `~/pi-workbench`.
`machine_setup.yaml` registers it through Pi on both install and update:

```sh
pi install "$HOME/pi-workbench"
```

For development before provisioning, use `pi install /absolute/path/to/home/pi-workbench`.
Local packages load in place; changes follow the checkout, not an npm release.
Use `/reload` after changes. Pi supplies runtime peers; installing this local
package needs no npm dependency installation. `pi-subagents@0.78.0` is provisioned
separately and remains the execution engine. Do not bundle or import its internals.

## Interface

The `workbench` skill documents orchestration policy. `/dispatch`, `/review`,
`/ship`, and `/babysit-pr` load it while retaining their original authority limits.

The model-facing `workbench` tool supports:

| Action | Inputs beyond action/taskId | Effect |
| --- | --- | --- |
| `create` | `title`, `criteria[]` | Create and select a private task contract |
| `status` | optional `taskId` | Counts, revision, attention IDs, latest four receipts, artifact paths |
| `list` | none | Compact task list, with omission count |
| `add` | `revision`, `criterion` | Append a stable acceptance ID |
| `record` | `revision`, `assertion`, `state`, `note`, `evidence[]`, `scope` | Parent assessment and history |
| `handoff` | `revision`, `agent`, `objective` | Prepare native file-only launch parameters; **no launch** |
| `receipt` | `revision`, `handoffId`, `state`, `runId`, `summary`, `blockers[]` | Record parent-attested native outcome |

Assertion states: `pending`, `passed`, `failed`, `blocked`, `waived`. Passed
assessments require existing evidence files. Passed/waived assessments require
an exact patch/check scope; every transition needs an explanation. Waivers need
user/repository authorization, not just a nonempty string.

Example native-tool sequence (UUIDs/revisions come from actual tool results):

```json
{"action":"create","title":"Validate endpoint","criteria":["Invalid input returns 400","Fresh review covers the exact patch"]}
```

```json
{"action":"handoff","taskId":"<returned UUID>","revision":0,"agent":"worker","objective":"Implement only src/endpoint.ts and its unit tests. Preserve unrelated work. Validate invalid input returns 400. Stop on schema ambiguity."}
```

Inspect the resolved user-scope builtin role first, then pass the returned
`subagent` object to the **native subagent tool** only when delegation is authorized.
It uses fresh context, explicit cwd, no worktree, async execution, an absolute
output path, and `outputMode: file-only`. Add any parent-required acceptance/index
preservation options. Native output persistence works for read-only reviewers
without granting them file-write tools.

Wait for an actual native terminal result. Read report sections relevant to
findings, uncertainty, or decisions. Record a bounded receipt summary and all
blockers; assess criteria separately after parent validation. Errors remain on
the native failure path, not hidden by a result-transforming hook. Cancellation,
recovery, budgets, model selection, child permissions, and completion notifications
remain entirely native. Prepared handoffs are never presented as running jobs.

### Persistence and trust

Default state is `~/.pi/agent/workbench/<checkout-hash>/<task-uuid>/`; the standard
`PI_CODING_AGENT_DIR` override moves it with the Pi agent directory. State uses
canonical checkout paths, private directories/files, atomic contract replacement,
exclusive mutation locks, and revision checks. Re-read status after a conflict.
A crash can leave `.lock`; inspect the task and native runs before manually
removing it. No automatic stale-lock stealing or retrying launches.

The owning Pi session alone can mutate a task through the API. Selection follows
session-branch entries. A resumed owner retains access; a different/forked session
can inspect/select a task but cannot mutate it. Resume the original owner, or
explicitly create a new task with the remaining requirements. No implicit takeover.
Malformed state fails closed. Tasks support 64 criteria and 64 handoffs; contract
JSON is bounded at 256 KiB. Limits fail explicitly rather than truncating history.

This is **trusted same-user code, not a sandbox**. Other tools/processes can edit
the JSON or files. History is append-only through the API, not tamper-proof.
Receipts are parent-attested, not cryptographically/runtime-attested outcomes.
`criteria-recorded-ready` is only a count of parent assessments, not proven task
completion. Handoff blockers require separate attention even when criteria pass.

Evidence stores file hashes (maximum 8 MiB per file). Hashes detect changed/missing
reports, **not changed source patches**. Patch scope is parent-recorded; after
source changes reset affected criteria and revalidate. Required checks, fresh
independent review, exact-head merge checks, and delivery authority still apply.
Do not copy credentials or unredacted sensitive logs into artifacts or exports.
Artifacts are private machine-local state; no retention/deletion daemon exists.
Remove obsolete task directories explicitly only after native work has settled.

## Herdr: option A

No Herdr dependency is needed outside explicit terminal actions. Nothing polls,
starts processes, creates/focuses panes, or reports lifecycle state automatically.

- `/workbench`: selected task's status and artifact locations.
- `/workbench list` / `/workbench select <id>` / `/workbench status [id]`.
- `/workbench herdr`: publish this session's display-only `workbench` token for
  **60 seconds**. Add `$workbench` to your existing Herdr sidebar row to display it.
  Refresh explicitly; stale metadata expires rather than masquerading as live.
- `/workbench herdr clear`: clear only this session's custom tokens.
- `/workbench focus [id]`: explicitly focus the owning Pi pane, after verifying
  host, Herdr socket, pane ID, and the live recognized Pi session-file binding.
  Reused panes, missing sessions, unknown states, and remote bindings fail closed.

Ordinary shell inspection (run from the task's checkout):

```sh
node "$HOME/pi-workbench/cli.mjs" list
node "$HOME/pi-workbench/cli.mjs" status <task-id>
node "$HOME/pi-workbench/cli.mjs" focus <task-id>  # explicit Herdr navigation
```

Official Herdr Pi integration owns pane lifecycle/session identity; pi-subagents
owns child state and its existing metadata. Workbench uses a separate metadata
source and token, never overwrites titles/summary/agent status, and never stops a
child or server. Herdr commands have a 3-second timeout and use argv, never shell
interpolation. A focus action can race a pane replacement after inspection; the
binding check reduces stale targeting but is not an atomic server-side lease.

## Development and validation

```sh
cd home/pi-workbench
npm ci --ignore-scripts
npm run check
npm test
```

Development peers are pinned in `package-lock.json`; Pi supplies runtime peers.
Tests exercise the real extension factory/TypeBox schema without model calls,
contract transitions, evidence freshness, locks/revisions, branch restoration,
artifact-only briefs, and fake Herdr argv/session checks. TypeScript is checked
strictly; `.mjs` core behavior is covered by tests (not JS static checking).

Live provider-backed delegation, terminal rendering, sidebar configuration, and
Herdr focus/publication are separate integration checks: mocked tests are not
claims that these have run. No shipping, external writes, or model requests are
authorized merely by installing or testing this package.
