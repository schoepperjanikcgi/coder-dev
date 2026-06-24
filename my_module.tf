terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.12"
    }
  }
}

variable "url" {
  description = "The URL of the Git repository."
  type        = string
}

variable "base_dir" {
  default     = ""
  description = "The base directory to clone the repository. Defaults to \"$HOME\"."
  type        = string
}

variable "agent_id" {
  description = "The ID of a Coder agent."
  type        = string
}

locals {
  base_dir = var.base_dir != "" ? var.base_dir : "$HOME"
}

resource "coder_script" "git_clone_custom" {
  agent_id           = var.agent_id
  script             = <<-EOT
    #!/bin/bash

    mkdir -p ~/.ssh

    if ! grep -q github.com ~/.ssh/known_hosts 2>/dev/null; then
      ssh-keyscan github.com >> ~/.ssh/known_hosts
    fi

    echo "Test if git exists"
    git --version
    echo "GIT_SSH_COMMAND=$GIT_SSH_COMMAND"
    env | grep GIT

    echo "Test if git clone works"
    if [ ! -d ~/nodejs-test ]; then
      echo "Actually cloning..."
      echo "Cloning ${var.url} into ${local.base_dir}/nodejs-test"
      git clone "${var.url}" "${local.base_dir}/nodejs-test"
    fi

    echo "Git clone finish"
  EOT
  display_name       = "Git Clone Custom"
  icon               = "/icon/git.svg"
  run_on_start       = true
  start_blocks_login = true
}