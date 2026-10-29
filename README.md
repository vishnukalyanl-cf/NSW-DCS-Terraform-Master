# NSW-DCS-Terraform-Master

Cloudflare Terraform (DNS + Redirect Rules)

GitOps setup for managing Cloudflare zones with Terraform:

- Code lives in GitHub. Changes are made on a **feature branch**, applied and verified from that branch, then merged to **main** by pull request.
- A **manually triggered** GitHub Actions workflow runs init / fmt / validate / plan / apply / drift-check / state-list on the branch you pick.
- **Apply** requires approval (GitHub environment "production"), applies the exact saved plan, and is blocked if the branch would undo changes that are already live.
- After a merge, main is automatically checked against Cloudflare (the plan should show no changes).
- State is stored in **Cloudflare R2** (S3-compatible backend) with native locking, **one state file per zone**.
- Customers only edit **zones/<zone>.tfvars**. All resource code lives in modules.

~~~
 Laptop                      GitHub                                               Cloudflare
 git checkout -b feature/x
 edit zones/<zone>.tfvars
 git push  -------------->  feature/x  (auto: fmt + validate)
                              |
                              | Actions > Run workflow (branch feature/x, zone, action)
                              v
                           checks -> plan -> safety checks -> [approval] -> apply --->  Cloudflare API
                                                  \__ state, lock, last-applied __/--->  R2 bucket
                              |
                              | verify, then pull request + manual merge
                              v
                           main  (auto: fmt + validate + post-merge check = "No changes")
~~~

## Repository layout

| Path | Purpose | Who edits |
|---|---|---|
| .github/workflows/terraform.yml | CI/CD pipeline | Platform team |
| .github/CODEOWNERS | Required reviewers per folder (optional) | Platform team |
| root/versions.tf | Pins Terraform + Cloudflare provider versions | Platform team |
| root/backend.tf | R2 state backend + locking (bucket/key passed at init) | Platform team |
| root/providers.tf | Cloudflare provider (token from env var) | Platform team |
| root/variables.tf | Inputs every zone file must provide | Platform team |
| root/main.tf | Zone-ID safety check + module calls | Platform team |
| root/imports.tf | Adopt existing dashboard-created records/rules | Platform team |
| root/outputs.tf | Outputs after apply | Platform team |
| root/.terraform.lock.hcl | Provider lock file (generate, then commit) | Generated |
| modules/dns-records/ | cloudflare_dns_record resources | Platform team |
| modules/redirect-rules/ | cloudflare_ruleset (Single Redirects) | Platform team |
| zones/*.tfvars | **Per-zone config: zone ID, DNS records, redirect rules** | **Customer** |
| scripts/lock-providers.sh | Generates the provider lock file | - |
| scripts/local-plan.sh | Runs a plan locally for one zone | - |
| scripts/list-existing.sh | Lists existing record IDs / redirect ruleset (for imports) | - |

---

## 1. One-time Cloudflare setup

### 1.1 R2 bucket for state
1. Dashboard > R2 > Create bucket, e.g. **acme-terraform-state** (private).
2. R2 > Manage R2 API tokens > Create API token: **Object Read & Write**, scoped to that bucket only.
3. Save the **Access Key ID** and **Secret Access Key**.
4. Optional: R2 lifecycle rule to expire objects under **backups/** after e.g. 90 days.

### 1.2 Cloudflare API token for Terraform
My Profile (or Account) > API Tokens > Create Token > Custom token:

| Permission | Why |
|---|---|
| Zone > Zone > Read | Zone-ID safety check |
| Zone > DNS > Edit | DNS records |
| Zone > Single Redirect > Edit | Redirect rules |

Zone Resources: include only the zones Terraform will manage (add new zones here later).

### 1.3 IDs
Account ID and each Zone ID: zone **Overview** page > right sidebar > API section.

---

## 2. One-time GitHub setup

1. Create a private repo, default branch **main**, and push this folder.
2. Settings > Secrets and variables > Actions:

| Type | Name | Value |
|---|---|---|
| Secret | CLOUDFLARE_API_TOKEN | Token from 1.2 |
| Secret | R2_ACCESS_KEY_ID | From 1.1 |
| Secret | R2_SECRET_ACCESS_KEY | From 1.1 |
| Variable | TF_STATE_BUCKET | e.g. acme-terraform-state |
| Variable | CLOUDFLARE_ACCOUNT_ID | Your account ID |

3. Settings > Environments > New environment **production**:
   - Required reviewers: 1-2 people/team (apply waits for them).
   - Deployment branches and tags: **Selected branches** > add **feature/*** and **main** (applies run from feature branches; main is kept for rollbacks).
   - (Private repos need GitHub Team/Enterprise for required reviewers.)
4. Settings > Rules > Rulesets > New branch ruleset targeting **main**:
   - Require a pull request before merging (1 approval recommended).
   - Require status checks to pass: **Format & validate**, with **Require branches to be up to date before merging** turned on.
   - Block force pushes.
5. Optional: fill in .github/CODEOWNERS with your teams.

---

## 3. First-time bootstrap

~~~bash
# Generate and commit the provider lock file (required: CI uses -lockfile=readonly)
./scripts/lock-providers.sh
terraform fmt -recursive
git add .
git commit -m "Initial Cloudflare Terraform setup"
git push origin main
~~~

Then:
1. Edit a **test zone** file in zones/ with a harmless record (e.g. a "tf-test" TXT record).
2. GitHub > Actions > **Terraform - Cloudflare** > Run workflow > zone = your file name (without .tfvars), action = **plan**.
3. Run again with action = **apply**, approve, and check the dashboard (records show comment "Managed by Terraform").
4. Run **state-list** to confirm state exists in R2 at zones/<zone>/terraform.tfstate.

---

## 4. Day-to-day runbook

Changes are applied from a **feature branch** and merged to main only after they are verified.

~~~bash
git checkout main && git pull
git checkout -b feature/add-blog-record
# edit ONLY zones/<your-zone>.tfvars
terraform fmt -recursive
git commit -am "DNS: add blog A record"
git push -u origin feature/add-blog-record
~~~

1. The push runs **Format & validate** automatically on the branch.
2. Actions > Terraform - Cloudflare > Run workflow: **branch feature/add-blog-record**, zone, action **plan**. Read the run summary.
3. Run again with action **apply**. A reviewer clicks **Review deployments > Approve**.
4. Verify in the dashboard / with dig.
5. Open a pull request to main, get it reviewed, and **merge it manually**.
6. The merge triggers the **post-merge check** on main. It should show "main matches Cloudflare". It also marks main as the zone's new baseline.
7. Delete the feature branch.

| Action / event | What it does | Changes Cloudflare? |
|---|---|---|
| (push to any branch) | fmt -check, init -backend=false, validate | No |
| (merge to main) | Plans each changed zone; fails if main does not match Cloudflare | No |
| plan | checks, init (R2), validate, plan, summary | No |
| apply | plan, safety checks, **approval**, state backup, apply saved plan, record last-applied commit | **Yes** |
| drift-check | plan -refresh-only: shows changes made outside Terraform | No |
| state-list | Lists resources Terraform manages for the zone | No |

Apply safety checks (automatic):
- The branch must contain the latest main. Otherwise: git merge origin/main, push, re-run.
- The branch must contain the last commit applied to that zone. This blocks a second branch from silently undoing a first branch that was applied but not yet merged.

Rollback:
- Before merging: revert the change on the feature branch (or run **apply from main**, which puts the zone back to what main says; the run shows a warning listing the branch it undoes).
- After merging: git revert the merge on a new branch, apply it, then merge.

Rules of thumb:
- **One open, applied branch per zone at a time.** Merge it soon after verifying it.
- Never merge a branch that was not applied: the post-merge check will fail.
- Removing an entry from the file **deletes** it in Cloudflare.
- Never rename a record key (e.g. root_a) or a rule name; add a new one and remove the old one.
- Don't edit Terraform-managed records/redirects in the dashboard; they will be overwritten. Use drift-check.

---

## 5. Adding a new zone

1. cp zones/example-com.tfvars zones/newzone-io.tfvars
2. Set zone_id, zone_name, records and rules.
3. Add the zone to the Cloudflare API token's zone resources.
4. On a feature branch: commit, push, run the workflow on that branch with zone = newzone-io (plan, then apply), verify, then merge. A new state file is created automatically.

---

## 6. Onboarding a zone that already has records / rules

Creating a record that already exists fails, so **adopt** existing objects instead:

~~~bash
CLOUDFLARE_API_TOKEN=... ./scripts/list-existing.sh <zone_id>
~~~

DNS records:
1. Add each record to dns_records with **exactly** the current values.
2. Map its key to the record ID in dns_record_imports, e.g. root_a = "372e6795...".
3. Run plan: expect "will be imported" and ideally 0 to change. Then apply.

Redirect rules: Terraform owns the **entire** redirect ruleset of the zone. Any rule not in the file is **removed** on apply.
1. Re-create every existing rule in redirect_rules.
2. Set redirect_ruleset_import_id to the ruleset ID.
3. Plan, review, apply.

Records not listed in the file are left untouched.

---

## 7. Running a plan locally (optional)

~~~bash
export CLOUDFLARE_API_TOKEN=...
export AWS_ACCESS_KEY_ID=...          # R2 access key
export AWS_SECRET_ACCESS_KEY=...      # R2 secret
export CLOUDFLARE_ACCOUNT_ID=...
export TF_STATE_BUCKET=acme-terraform-state
./scripts/local-plan.sh example-com
~~~

Apply should always go through the pipeline.

---

## 8. State management

| Topic | How |
|---|---|
| Location | s3://<bucket>/zones/<zone>/terraform.tfstate (R2) |
| Locking | use_lockfile = true writes terraform.tfstate.tflock during runs (R2 supports the required conditional writes). The workflow also queues runs per zone. |
| Backups | R2 has no object versioning, so the pipeline copies state to backups/<zone>/<timestamp>.tfstate before every apply |
| Last applied | zones/<zone>/last-applied.txt records the commit and branch of the last apply (reset to main by the post-merge check); used by the apply safety checks |
| Restore | Download a backup, then from root/ (after init): terraform state push restore.tfstate |
| Stuck lock | terraform force-unlock <LOCK_ID> (locally, after init) |

Alternatives if preferred: HCP Terraform, AWS S3, GCS, Azure Blob. Change root/backend.tf and run terraform init -migrate-state.

---

## 9. Troubleshooting

| Symptom | Fix |
|---|---|
| "identical record already exists" / CNAME conflict | Record already exists: import it (section 6) |
| Redirect ruleset already exists for the phase | Set redirect_ruleset_import_id (section 6) |
| "zone_id ... belongs to 'x', not 'y'" | Wrong zone ID in the tfvars file |
| 403 / authentication error | Token permissions or zone scope (1.2) |
| Redirect not working | Source hostname must be proxied (orange cloud); check rule order and plan rule limits |
| Lock timeout | Another run is in progress; wait, or force-unlock if it crashed |
| fmt -check fails | Run terraform fmt -recursive and push |
| Init fails with lock file error | Run ./scripts/lock-providers.sh and commit root/.terraform.lock.hcl |
| "Branch ... is behind main" | git merge origin/main on your branch, push, run again |
| "The last apply to <zone> came from '<branch>'" | Another branch was applied but not merged. Merge it to main first (or roll it back), merge main into your branch, run again |
| Post-merge check fails on main | main does not match Cloudflare: a branch was merged without being applied, or an unmerged branch was applied. Apply the missing branch, or run apply from main to make Cloudflare match main |
| Apply job never starts / "branch not allowed" | Add the branch pattern (e.g. feature/*) to the production environment's deployment branches |

## 10. Upgrading the provider

1. Bump version in root/versions.tf.
2. Run ./scripts/lock-providers.sh (it uses -upgrade) and commit the lock file.
3. Read the provider CHANGELOG (v5 minors can rename fields) and run **plan** for every zone before applying.
