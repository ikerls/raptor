# Repository Setup Checklist

## Initial Setup

### 1. Confirm Raptor Identity

- [ ] Confirm `raptor` / `ikerls` identity in Containerfile, Justfile, Artifact
      Hub metadata, cleanup workflow, ISO configuration, and local bootc docs.

### 2. Enable GitHub Actions

- [ ] Settings → Actions → General → Enable workflows
- [ ] Set "Read and write permissions"

### 3. Configure Testing and Production Branches

This template uses a **two-branch model**: `main` publishes `:stable-testing`
candidate images, and `stable` publishes `:stable` production images.
Promotion is an exact-tree, single-commit PR from `main` to `stable` opened
automatically by `.github/workflows/promote-main-to-stable.yml`. This is the
repository-local personal-account adaptation; it does not request reviewers.

Create `stable` as an exact copy of `main`, then return to `main`:

```bash
git switch main
git switch -c stable
git push --set-upstream origin stable
git switch main
```

- [ ] Never commit directly to `stable`; it receives only promotion PRs
- [ ] Keyless signing is enabled by default; after the first build, verify it
      (see "Verify Image Signing" below) so the promotion release gate can
      check signatures and report `release/ready`

Promotion PR requirements:

- Raptor is a personal-account repository. Its local promotion workflow does
  not require an organization maintainer team or request reviewers.
- Set `stable`'s required approvals to choose your automation level: `0` =
  fully automatic promotion, `1` = a maintainer approves, then auto-merge
- The release gate is advisory by default; add the promote workflow as a
  required check on `stable` if a `release/blocked` result should block merges

### 4. First Push

```bash
git add .
git commit -m "feat: initial customization"
git push origin main
```

### 5. Enable Renovate (Required)

- [ ] Confirm repository Actions variable **`APP_CLIENT_ID`** is `3391622`
- [ ] Confirm repository Actions secret **`APP_PRIVATE_KEY`** belongs to that
      installed GitHub App
- [ ] Enable **Settings → General → Pull Requests → Allow auto-merge**
- [ ] Configure branch protection for `main`:
  - Settings → Branches → Add rule
  - Set **Branch name pattern** to `main`
  - Enable "Require a pull request before merging"
  - Enable "Require status checks to pass before merging"
  - Add `validate` as a required status check
  - Enable "Require branches to be up to date before merging"
- [ ] Configure branch protection for `stable`: require a pull request before
      merging so only promotion PRs land there
- [ ] Renovate will create a PR to pin your GitHub Actions to SHAs

Renovate targets `main`; approved changes reach `stable` through the promotion flow.

**Agent skills:** `finpilot-onboarding` (branch protection), `finpilot-ci` (Renovate config)

### 6. Add "What Makes this Raptor Different" to README

- [ ] Open `README.md`
- [ ] Keep the current Raptor details accurate after every package, app, or
      service change
- [ ] Update the `*Last updated*` timestamp

**Agent skills:** `finpilot-onboarding` (raptor section), `finpilot-maintain` (maintenance requirement)

### 7. Participate in finpilot maintenance
- [ ] Use [finpilot issues](https://github.com/projectbluefin/finpilot/issues/new/choose)
  for reusable template or build-system improvements.
- [ ] Select the Clanker opt-in only on issues you create to send them to
  `3-clanker-queue`; maintainers may also apply that label.
- [ ] Port structural template changes to this repository through a focused PR.
  Renovate manages dependencies only; it does not synchronize arbitrary
  template files.

### 8. Deploy

Test the candidate image from `main`:

```bash
sudo bootc switch --transport registry ghcr.io/ikerls/raptor:stable-testing
sudo systemctl reboot
```

After merging the promotion to `stable`, deploy the production image:
```bash
sudo bootc switch --transport registry ghcr.io/ikerls/raptor:stable
sudo systemctl reboot
```

## Optional: Production Features

### Verify Image Signing (Enabled by Default)

Images are signed automatically with keyless OIDC signing — no keys or
secrets to configure. After the first green build, verify the signature:

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/ikerls/raptor/.github/workflows/" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/ikerls/raptor:stable-testing
```

To disable signing (not recommended), comment out the `Sign and publish`
step in `.github/workflows/build-image.yml`. Unsigned images fail the
promotion release gate (`release/blocked`).

**Agent skill:** `finpilot-templates` (signing verification)

### Enable Rechunking (Optional)

- [ ] Edit `.github/workflows/build-image.yml`
- [ ] Set `ENABLE_RECHUNKING: "true"`
- [ ] Keep the default `RECHUNK_MAX_LAYERS: "128"` unless you have measured a reason to change it
- [ ] Confirm a publish build completes before deploying the new image

The current OCI-native chunkah action does not use `/usr/libexec/bootc-base-imagectl`. Package cadence classification is a separate advanced setup and is not required for basic rechunking.

**Agent skill:** `finpilot-ci` (rechunking compatibility and workflow setup)

## Agent Handoff Reference

Which skill to load for each checklist block above:

| Checklist step                        | Skill                                       |
| ------------------------------------- | ------------------------------------------- |
| Rename (step 1)                       | `finpilot-templates`, `finpilot-onboarding` |
| Enable Actions (step 2)               | `finpilot-onboarding`                       |
| Branches + promotion (step 3)         | `finpilot-onboarding`, `finpilot-ci`        |
| Renovate + branch protection (step 5) | `finpilot-onboarding`, `finpilot-ci`        |
| Raptor section (step 6)               | `finpilot-onboarding`, `finpilot-maintain`  |
| Signing verification (default on)     | `finpilot-templates`                        |
| Rechunking (optional)                 | `finpilot-ci`                               |

**Cross-link requirement**: Whenever you add or remove a package, app, or service **after** initial setup, update the README raptor section and its `*Last updated*` date. This is required by the `finpilot-maintain` skill.
