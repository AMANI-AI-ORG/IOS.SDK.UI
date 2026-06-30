# Release Pipeline

This project uses a **4-workflow release pipeline** to test, version, publish, and optionally measure the source payload size of iOS UI SDK releases through GitHub Actions.

---

## Workflow Overview

The pipeline has four workflows, each owning a distinct phase of the release lifecycle:

| Workflow | File | Trigger | Phase | Purpose |
|----------|------|---------|-------|---------|
| **① Release · Prepare** | [`workflows/release.yml`](workflows/release.yml) | `workflow_dispatch` (manual) | Pre-PR gate | Runs tests on `main`, then creates the `release/{version}` branch and opens the release PR |
| **② Release · Verify** | [`workflows/release-ci.yml`](workflows/release-ci.yml) | `pull_request` opened / synchronize | PR validation | Runs tests on the release PR branch and verifies the podspec version |
| **③ Release · Ship** | [`workflows/publish-release.yml`](workflows/publish-release.yml) | `pull_request` closed (merged) | Post-merge publish | Creates the git tag, updates `Mobile_SDK_Repo` with the new CocoaPods spec, creates the GitHub Release, and deletes the release branch |
| **④ Release · Measure** | [`workflows/release-measure.yml`](workflows/release-measure.yml) | `workflow_dispatch` (manual) **or** called by ③ when opted in | Size telemetry | Measures the source payload size of `AmaniUI`, updates metrics files, and opens a metrics PR |

---

## When does ④ Release · Measure run?

Measure is **opt-in** to keep normal releases fast. It runs in three scenarios:

1. **Manual trigger** — Actions → **④ Release · Measure** → Run workflow  
2. **Tick the box in ① Release · Prepare** — set *"Run ④ Release · Measure after publish"* to `true`  
3. **Add the `measure-size` label manually** to the release PR before merge  

If neither the label nor a manual trigger is present, Ship publishes the release without running Measure.

> **How the metrics land in `main`:**  
> Measure opens a `chore(metrics): ...` PR from `metrics/ui-size-<version>` against `main`.  
> It does **not** push directly to `main`.

---

## How they differ

- **Prepare** is the entry point. A human starts it manually. It validates `main` before creating a release PR.
- **Verify** is the PR gatekeeper. It re-runs tests on the release branch and ensures the podspec version is correct.
- **Ship** is the publisher. It tags the release, publishes the CocoaPods spec to `Mobile_SDK_Repo`, creates the GitHub Release, and cleans up the release branch.
- **Measure** is the telemetry stage. It measures the source payload footprint of the SDK and opens a metrics PR.

In short: **Prepare opens the door, Verify checks the work, Ship publishes it, Measure tracks its size.**

---

## Flow Diagram

```text
┌────────────────────┐       ┌────────────────────┐       ┌────────────────────┐       ┌────────────────────┐
│ ① Release·Prepare  │ PR ─► │ ② Release·Verify   │ Mrg ► │ ③ Release·Ship     │ ────► │ ④ Release·Measure  │
│  (release.yml)     │       │ (release-ci.yml)   │       │ (publish-release)  │       │ (release-measure)  │
│                    │       │                    │       │                    │       │                    │
│ 1. Unit tests      │       │ 1. Unit tests      │       │ 1. Extract version │       │ 1. Measure source  │
│ 2. Create PR       │       │ 2. Verify version  │       │ 2. Create tag      │       │    payload         │
│ 3. Add labels      │       │ 3. Push fix commit │       │ 3. Update spec repo│       │ 2. Update metrics  │
│    (optional)      │       │    if needed       │       │ 4. GitHub Release  │       │ 3. Open metrics PR │
└────────────────────┘       └────────────────────┘       │ 5. Cleanup branch  │       └────────────────────┘
                                                          └────────────────────┘
                                                                  │
                                                                  └── if PR has
                                                                     `measure-size` label
                                                                     (or run ④ manually)
```

---

## Full Release Flow

### Option A: Recommended — Start from Prepare

Go to **Actions** → **① Release · Prepare** → **Run workflow**

This is the recommended entry point for normal releases.

Flow:

1. Run unit tests on `main`
2. If tests pass, create `release/<version>` branch
3. Bump `AmaniUI.podspec` version
4. Open a release PR to `main`
5. Optionally add the `measure-size` label
6. After merge, Ship publishes the release
7. If opted in, Measure runs after publish

### Option B: Manual release PR

You can also create the release branch and PR yourself:

```bash
git checkout -b release/1.3.0
git push origin release/1.3.0
```

Then open a PR to `main` with a title like:

```text
release: 1.3.0
```

Once merged, **③ Release · Ship** takes over automatically.

---

## Usage

### 1. Start a Release

Go to **Actions** → **① Release · Prepare** → **Run workflow**

Inputs:

| Input | Example | Description |
|-------|---------|-------------|
| `version` | `1.3.0` | Release version |
| `release_notes` | See below | One item per line, badges are applied on publish |
| `dry_run` | `false` | When `true`, only tests run |
| `measure_size` | `false` | When `true`, triggers ④ after publish |

Example release notes:

```text
Feature: Added new T&C flow
Fix: Resolved OTP screen layout issue
Improvement: Reduced source payload size
Update: Refined NFC flow texts
Change: Updated minimum supported integration docs
```

### 2. Review the PR

After Prepare completes:

- A PR titled `release: <version>` appears targeting `main`
- **② Release · Verify** runs automatically on the PR branch
- If needed, podspec version is corrected and pushed
- Review the PR and merge when ready

### 3. Release Publishes Automatically

After the PR is merged:

- A git tag is created
- A GitHub Release is created
- `Mobile_SDK_Repo` is updated with the new CocoaPods spec
- The release branch is deleted

### 4. Optional Measurement

If `measure_size` was enabled or the PR had the `measure-size` label:

- **④ Release · Measure** runs
- Source payload metrics are updated
- A metrics PR is opened against `main`

---

## Publish Behavior

When the release PR is merged, **③ Release · Ship** performs these actions:

1. Extract version from `release/<version>` branch name
2. Create and push the source tag
3. Generate `AmaniUI.podspec.json`
4. Publish the spec to `Mobile_SDK_Repo` under:

```text
Specs/AmaniUI/<version>/AmaniUI.podspec.json
```

5. Create the GitHub Release
6. Delete the release branch

---

## Measure Behavior

When measurement runs, **④ Release · Measure**:

1. Packages:
   - `AmaniUI.podspec`
   - `Sources/AmaniUI`
2. Measures:
   - zipped source payload size
   - uncompressed source payload size
3. Updates metrics files under `.github/metrics/`
4. Opens a PR with the refreshed metrics

---

## Metrics Files

The following files are maintained by **④ Release · Measure**:

- `metrics/UI_SIZE_HISTORY.md`
- `metrics/amaniui-source-size.json`
- `metrics/ui-size-latest.json`
- `metrics/ui-size-history.json`

---

## Release Notes Badge Mapping

The following keywords are detected automatically during publish:

| Keyword | Badge |
|---------|-------|
| `fix` / `fixed` / `fixes` | Fix 🐛 |
| `feature` | Feature ✨ |
| `improvement` | Improvement 🛠️ |
| `update` / `updated` | Update 🔄 |
| `change` / `changed` | Change ♻️ |

---

## Notes

- `Mobile_SDK_Repo` publishing requires `MOBILESDKREPO_PAT`
- GitHub Release creation uses the repository `GITHUB_TOKEN`
- Measure is skipped for pre-releases by default
- This pipeline publishes **source-based CocoaPods distribution**, not a binary framework

