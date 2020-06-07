#!/usr/bin/env bash

#set -e
#set -o pipefail

echo "##################################################"
echo "# Bootstrapping ${HOSTNAME}                      #"
echo "##################################################"

OSX_VERSION="$(/usr/bin/defaults read loginwindow SystemVersionStampAsString)"
TMP_DIR="$(/usr/bin/mktemp -d)"
REPO_URL="https://github.com/jcsmith/bootstrap-workstation.git"

echo "Detected OSX ${OSX_VERSION}"

echo "##################################################"
echo "# Installing xcode and accepting agreements      #"
echo "##################################################"

cd $TMP_DIR || exit 1

/usr/bin/xcode-select --install
echo "Enter sudo password."
sudo xcodebuild -license accept

echo "##################################################"
echo "# Installing ansible via pip                     #"
echo "##################################################"

pip3 install --user ansible

echo "##################################################"
echo "# Creating initial ansible configuration         #"
echo "##################################################"

cat <<-EOF > "${TMP_DIR}/inventory"
[localhost]
127.0.0.1
EOF

cat <<-EOF > "${TMP_DIR}/requirements.yml"
---
- name: geerlingguy.homebrew
EOF

echo "##################################################"
echo "#  Installing modules from ansible galaxy        #"
echo "##################################################"
ansible-galaxy install -r requirements.yml

echo "##################################################"
echo "#  Installing homebrew and base packages         #"
echo "##################################################"
cat <<EOF >> "${TMP_DIR}/bootstrap.yml"
---
- hosts: all
  connection: local

  vars:
    homebrew_installed_packages:
      - git

  roles:
    - role: geerlingguy.homebrew
EOF

ansible-playbook bootstrap.yml -i inventory

echo "##################################################"
echo "#  Cloning ${REPO_URL}                           #"
echo "##################################################"

REPO_DIR="${REPO_URL##*/}"
REPO_DIR="${REPO_DIR%%.git}"


git clone "${REPO_URL}"
cd "${TMP_DIR}/${REPO_DIR}"
pwd
ls -lah

echo "##################################################"
echo "# Installing additional modules from             #"
echo "# from ansible galaxy.                           #"
echo "##################################################"
ansible-galaxy install -r ansible/requirements.yml

echo "##################################################"
echo "# Executing ansible-playbook for default config. #"
echo "##################################################"

ansible-playbook ansible/main.yml -i ansible/inventory
