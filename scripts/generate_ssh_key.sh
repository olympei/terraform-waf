#!/bin/bash

set -e

KEY_NAME="gitlab_ci_ssh"

# Generate SSH key pair
ssh-keygen -t ed25519 -C "gitlab-ci" -f $KEY_NAME -N ""

# Output for GitLab
echo -e "\n✅ SSH key pair generated:"
echo "Public key (add to GitLab SSH keys):"
cat ${KEY_NAME}.pub

echo -e "\nPrivate key (add to GitLab CI/CD variable as SSH_PRIVATE_KEY):"
cat ${KEY_NAME}

# Move to .ssh if desired
mkdir -p ~/.ssh/gitlab-ci
mv $KEY_NAME ~/.ssh/gitlab-ci/id_ed25519
mv $KEY_NAME.pub ~/.ssh/gitlab-ci/id_ed25519.pub
chmod 600 ~/.ssh/gitlab-ci/id_ed25519

echo -e "\n📁 Keys moved to ~/.ssh/gitlab-ci/"
