terraform {
  required_version = ">= 1.0"

   required_providers {
    coder = {
      source  = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
    } 
/*     aws = {
      source  = "hashicorp/aws"
    } */
  }
}

resource "docker_image" "alpine" {
  name = "alpine:latest"
}

resource "docker_container" "test" {
  image = docker_image.alpine.image_id
  name  = "module-test-container"

  command = [
    "sh",
    "-c",
    "while true; do echo Hello; sleep 60; done"
  ]
} 


data "coder_workspace_owner" "me" {}

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
  encoded_clone_script = base64encode(templatefile("${path.module}/hello.sh", {
    GREETING          = "Seid gegrüßt",
    NAME              = "Thomas",
  }))
}

resource "coder_script" "git_clone_custom" {
  agent_id           = var.agent_id
  script             = <<-EOT
    #!/bin/bash
    echo "Starting custom git clone module"

    if ! grep -q github.com ~/.ssh/known_hosts 2>/dev/null; then
      mkdir -p ~/.ssh
      ssh-keyscan github.com >> ~/.ssh/known_hosts
    fi

    echo "Test if git exists"
    git --version

    echo "Test if git clone works"
    if [ ! -d ~/nodejs-test ]; then
      echo "Actually cloning..."
      echo "Cloning ${var.url} into ${local.base_dir}/nodejs-test"
      
      git clone "${var.url}" "${local.base_dir}/nodejs-test"
    fi
    echo "Data ${data.coder_workspace_owner.me.name}"
    echo "Git clone finish"

    echo "Start the script"
    echo -n '${local.encoded_clone_script}' | base64 -d > "${local.base_dir}/hello.sh"
    chmod +x "${local.base_dir}/hello.sh"

    "${local.base_dir}/hello.sh" 2>&1

  EOT
  display_name       = "Git Clone Custom"
  icon               = "/icon/git.svg"
  run_on_start       = true
  start_blocks_login = true
}
