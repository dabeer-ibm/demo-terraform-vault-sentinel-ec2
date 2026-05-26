# Demo: HCP Vault + Terraform + Sentinel → EC2

End-to-end HashiCorp stack demo with **policy-as-code**. Everything is set up manually via web UIs and CLIs — no bootstrap scripts.

> **Security note:** never paste real tokens/keys into chat or shared docs. If a credential is exposed, rotate it immediately.

---

## What you'll have at the end

- An IAM user in your AWS sandbox account whose keys are stored in **HCP Vault** at `aws/config/root`.
- A Vault role `demo-builder` that mints **short-lived AWS IAM users** for Terraform.
- An ed25519 SSH keypair stored in Vault KV at `kv/demo/ssh`.
- A **GitHub** repo containing the contents of this folder.
- An **HCP Terraform** workspace VCS-connected to that repo, with auto-apply on push to `main`.
- An **HCP Terraform Sentinel policy set** VCS-connected to the same repo (`sentinel/` subdir), enforcing:
  - `restrict-instance-type` — **hard-mandatory**
  - `require-tags` — **soft-mandatory**
  - `restrict-region` — **advisory**

---

## Prerequisites

| Tool | Install |
|---|---|
| `terraform` ≥ 1.7 | https://developer.hashicorp.com/terraform/install |
| `vault` ≥ 1.16 | https://developer.hashicorp.com/vault/install |
| `aws` CLI | configured as admin on a sandbox account |
| `gh` CLI | `brew install gh && gh auth login` |
| `ssh-keygen`, `jq`, `git` | standard |

You also need accounts with: AWS, [HCP](https://portal.cloud.hashicorp.com), [HCP Terraform](https://app.terraform.io) (a **Plus** tier org — Sentinel is gated behind it), GitHub.

---

## Step 1 — AWS bootstrap IAM user

Create a long-lived IAM user that Vault will use as its root credential.

```bash
aws iam create-user --user-name vault-bootstrap

aws iam attach-user-policy \
  --user-name vault-bootstrap \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam create-access-key --user-name vault-bootstrap
# → save AccessKeyId + SecretAccessKey for step 2
```

> Sandbox accounts only. In real environments scope this down.

---

## Step 2 — HCP Vault

In the [HCP portal](https://portal.cloud.hashicorp.com), create a Vault Dedicated cluster (Development tier is fine for the demo). Capture:

- `VAULT_ADDR` (public address from cluster overview)
- `VAULT_TOKEN` (admin token from "Generate token" button)
- `VAULT_NAMESPACE=admin`

Export those plus the AWS bootstrap keys from Step 1, then run the helper script:

```bash
export VAULT_ADDR="https://<your-cluster>.vault.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
export VAULT_TOKEN="<admin-token>"

export AWS_REGION="us-east-1"
export AWS_ROOT_ACCESS_KEY="<AccessKeyId from step 1>"
export AWS_ROOT_SECRET_KEY="<SecretAccessKey from step 1>"

./vault/setup.sh
```

The script ([vault/setup.sh](vault/setup.sh)) is idempotent and:
- enables the **AWS secrets engine** at `aws/` and configures the root credential,
- creates role **`demo-builder`** with admin policy (reusable across future AWS demos),
- enables **KV v2** at `kv/`,
- generates an **ed25519 SSH keypair** and writes it to `kv/demo/ssh`.

Verify:

```bash
vault read aws/creds/demo-builder
vault kv get -field=public_key kv/demo/ssh
```

---

## Step 3 — GitHub repo

Push the **entire demo folder** (Vault setup + Terraform + Sentinel + README) to a new GitHub repo:

```bash
# from the demo root: Assets/demos/terraform-vault-sentinel-ec2
gh repo create <your-user>/demo-terraform-vault-sentinel-ec2 --public --confirm

git init -b main
git add .
git -c user.email=you@example.com commit -m "initial"
git remote add origin https://github.com/<your-user>/demo-terraform-vault-sentinel-ec2.git
git push -u origin main
```

> The Terraform config lives in `terraform/` and the Sentinel policies in `sentinel/`. We'll point HCP Terraform at those subdirectories in the next steps.

---

## Step 4 — HCP Terraform workspace (VCS-connected)

In [HCP Terraform](https://app.terraform.io):

### 4a. Connect GitHub (one-time per org)
- Org settings → **Version Control** → **Add a VCS provider** → GitHub.com → complete the OAuth flow.

### 4b. Create project + workspace
- **Projects** → create `dabs-demos`
- **Workspaces** → **New workspace** → **Version control workflow**
  - VCS provider: the GitHub one you connected
  - Repository: `<your-user>/demo-terraform-vault-sentinel-ec2`
  - Workspace name: `demo-terraform-vault-sentinel-ec2`
  - Project: `dabs-demos`
  - **Advanced options → Terraform Working Directory: `terraform`**
  - Auto-apply: **on**

### 4c. Set workspace variables
In the workspace → **Variables** tab. Mark sensitive where indicated.

| Key | Category | Sensitive | Value |
|---|---|---|---|
| `VAULT_ADDR` | Env | no | (your VAULT_ADDR) |
| `VAULT_NAMESPACE` | Env | no | `admin` |
| `VAULT_TOKEN` | Env | **yes** | (your VAULT_TOKEN) |
| `aws_region` | Terraform | no | `us-east-1` |

---

## Step 5 — Sentinel policy set (VCS-connected)

In HCP Terraform → **Settings (org level)** → **Policy Sets** → **Connect a new policy set**:

- Policy framework: **Sentinel**
- VCS provider: the same GitHub one
- Repository: `<your-user>/demo-terraform-vault-sentinel-ec2`
- **Policies path: `sentinel`** (this is where [sentinel/sentinel.hcl](sentinel/sentinel.hcl) lives)
- Scope of policies: **Policies enforced on selected projects and workspaces** → pick project `dabs-demos`
- Name: `demo-guardrails`

Policies (defined in [sentinel/sentinel.hcl](sentinel/sentinel.hcl)):

| Policy | Enforcement | What it does |
|---|---|---|
| [restrict-instance-type](sentinel/restrict-instance-type.sentinel) | hard-mandatory | Only `t3.{micro,small,medium}` allowed for `aws_instance`. |
| [require-tags](sentinel/require-tags.sentinel) | soft-mandatory | Every `aws_instance` must have `Name`, `Environment`, `Owner`, `ManagedBy` tags. |
| [restrict-region](sentinel/restrict-region.sentinel) | advisory | Warns if AWS provider region is not `us-east-1`, `us-west-2`, or `ap-south-1`. |

---

## Step 6 — Deploy

Push any commit to `main` of the GitHub repo:

```bash
cd <local-clone>
git commit --allow-empty -m "trigger run"
git push
```

HCP Terraform queues a plan, runs Sentinel, then auto-applies (if no hard-mandatory policy fails). Outputs (`instance_id`, `public_ip`, `ssh_command`) are visible in the workspace UI.

To SSH:

```bash
vault kv get -field=private_key kv/demo/ssh > /tmp/demo.pem
chmod 600 /tmp/demo.pem
ssh -i /tmp/demo.pem ubuntu@<public_ip>
rm /tmp/demo.pem
```

---

## Step 7 — Show Sentinel blocking a bad change

Demonstrate the guardrail by violating each policy in turn.

### Hard-mandatory (blocks)
Edit [terraform/variables.tf](terraform/variables.tf) and change `instance_type` default to `m5.large`, then `git push`. The run will plan successfully and then **fail the policy check** — apply is blocked, no override possible without unlocking the policy.

### Soft-mandatory (overridable by admin)
Remove a tag (e.g. drop `Owner` from `aws_instance.demo.tags` in [terraform/main.tf](terraform/main.tf)) and push. The run halts at policy check; a workspace admin can click **Override and Continue**.

### Advisory (warns)
Change `aws_region` default to `eu-west-1` (or set the workspace variable). The run prints a warning but proceeds.

Revert after each demo so subsequent runs are green.

---

## Tear down

| Resource | How |
|---|---|
| EC2 + key pair | HCP Terraform → workspace → **Settings → Destruction** → Queue destroy plan |
| Workspace | Same page → Delete |
| Sentinel policy set | HCP Terraform → Org Settings → Policy Sets → `demo-guardrails` → Delete |
| GitHub repo | `gh repo delete <user>/demo-terraform-vault-sentinel-ec2 --yes` |
| Vault config | `vault secrets disable aws/` and `vault kv metadata delete kv/demo/ssh` |
| AWS bootstrap user | `aws iam delete-access-key …` then `aws iam delete-user --user-name vault-bootstrap` |

---

## File layout

```
terraform-vault-sentinel-ec2/
├── README.md
├── vault/
│   └── setup.sh                   ← idempotent Vault config (Step 2)
├── terraform/                     ← HCP Terraform working directory
│   ├── versions.tf
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── sentinel/                      ← HCP Terraform policy-set directory
    ├── sentinel.hcl
    ├── restrict-instance-type.sentinel
    ├── require-tags.sentinel
    └── restrict-region.sentinel
```

---

## What this demo proves

- **No static cloud credentials** in Terraform — short-lived AWS keys come from Vault, auto-revoked at end of lease.
- **Policy-as-code guardrails** via Sentinel — hard, soft, and advisory enforcement levels demonstrated on one stack.
- **GitOps** for both infrastructure and guardrails — GitHub is the source of truth for `terraform/` *and* `sentinel/`; HCP Terraform enforces plan → policy → apply on every change.
- **Bounded blast radius** — EC2 lands in default VPC + default SG; no networking is created.
