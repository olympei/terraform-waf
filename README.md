# Terraform WAF Module

Reusable WAFv2 ACL and RuleGroup modules supporting dynamic rules, managed rules, and environment separation.

## Structure

- `modules/waf`: Defines the Web ACL and associates rule groups + ALB
- `modules/waf_rule_group`: Creates custom rule groups, supports dynamic or rendered rules
- `examples/`: Demo configurations
- `waf_envs_multi/`: Split dev/prod environments
- `target-project/`: Shows module reuse from another project

## Usage

Refer to any example under `examples/` or environment folder for module usage.

```bash
cd examples/basic
terraform init
terraform plan
terraform apply
```

# GitLab SSH Key CI Setup

This folder contains a helper script to:

- Generate an SSH key pair for GitLab CI/CD
- Format it for CI/CD variables and GitLab SSH key setup

## 🚀 Usage

```bash
cd scripts
bash generate_ssh_key.sh
```

## 🛠️ Steps After Generation

1. **Public key**: Add it to GitLab → User Settings → SSH Keys
2. **Private key**: Add it to your project’s CI/CD Variables:
   - Key: `SSH_PRIVATE_KEY`
   - Type: `File`
   - Masked: ✅
   - Protected: ✅ (if needed)

3. ✅ Your `.gitlab-ci.yml` can now use SSH-based git operations securely.




✅ Step-by-Step: Generate SSH Keys for GitLab CI/CD Manually.
🔧 1. Generate the SSH key pair
Run this on your local machine or a trusted environment:

bash
Copier
Modifier
ssh-keygen -t ed25519 -C "gitlab-ci" -f gitlab_ci_ssh -N ""
-t ed25519: uses modern, secure key type

-C "gitlab-ci": label for GitLab

-f gitlab_ci_ssh: saves keys as gitlab_ci_ssh and gitlab_ci_ssh.pub

-N "": no passphrase

You’ll now have:

gitlab_ci_ssh (private key)

gitlab_ci_ssh.pub (public key)

🔐 2. Add the public key to GitLab
Go to: GitLab → User Settings → SSH Keys

Copy the content of gitlab_ci_ssh.pub:

bash
Copier
Modifier
cat gitlab_ci_ssh.pub
Paste it into the SSH key field

Click "Add key"

🛠️ 3. Add the private key to GitLab CI/CD
Go to: Your Project → Settings → CI/CD → Variables

Add a new variable:

Key: SSH_PRIVATE_KEY

Type: File

Value: paste contents of gitlab_ci_ssh:

bash
Copier
Modifier
cat gitlab_ci_ssh
✅ Check:

Masked ✅

Protected ✅ (only if your dev branch is protected)

📁 Optional: Move and store keys safely
bash
Copier
Modifier
mkdir -p ~/.ssh/gitlab-ci
mv gitlab_ci_ssh* ~/.ssh/gitlab-ci/
chmod 600 ~/.ssh/gitlab-ci/gitlab_ci_ssh
✅ Verification
Test from a local shell:

bash
Copier
Modifier
ssh -i ~/.ssh/gitlab-ci/gitlab_ci_ssh git@gitlab.com
It should output something like:

css
Copier
Modifier
Welcome to GitLab, @yourusername!
