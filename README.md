# Terraform Cloud/Enterprise Workspace Resource Migration Example

This tutorial demonstrates how to move resources between workspaces in Terraform Cloud/Enterprise. 

This workflow is useful when optimizing workspaces and following HashiCorp best practices for workspaces, including only 1 workspace per configuration per environment.

In this example, we'll first deploy a Security Group in AWS within an initial workspace, and then move the resource to a new workspace.

## Navigation

- [Overview](https://github.com/jitinaware/terraform-workspace-resource-migration-example#overview)
- [Prerequisites](https://github.com/jitinaware/terraform-workspace-resource-migration-example#prerequisites)
- [Procedure](https://github.com/jitinaware/terraform-workspace-resource-migration-example#procedure)
- [Cleanup](https://github.com/jitinaware/terraform-workspace-resource-migration-example#cleanup)

## Overview

At a high level, here are the steps involved:

<b>New Workspace</b>
1. Import configuration from old workspace (resource blocks)
1. Import resource into workspace

<b>Old Workspace</b>
1. Remove configuration from code
1. Remove resource(s) from workspace

## Prerequisites

1. jq utility | [download links](https://stedolan.github.io/jq/download/)
1. Authenticated to TFC/E via CLI (run `terraform login`)
1. Modify TFC/E org name in `versions.tf` in each workspace directory

## Procedure

1. Change directory into the old workspace and run the example deployment

    ```terraform
    cd old_workspace/
    
    terraform init
    terraform plan
    terraform apply --auto-approve
    ```
    We now have a single resource (security group) deployed. We can confirm the resource in the workspace resource list via the UI or CLI:

    ```hcl
    terraform state list

    aws_security_group.base
    ```

1. Run this command to retrieve the resourceid of the resource, which we'll need in a future step:

    ```hcl
    terraform show -json | jq -r '.values.root_module.resources[]  |  .address + " | " + .values.id'
    ```

    Your output should be something like this:

    ```sh
    aws_security_group.base | sg-000b5f84a61683d8f
    ```

    The second column lists the ids of the resources within this workspace. Make a note of the resource id for the security group.

1. We now need to move the resource block code describing the security group into the new workspace:

    ```sh
    mv sg.tf ../new_workspace/
    ```

    Note: we can also manually cut/paste the resource block code from the old workspace configuration to the new workspace configuration (`main.tf` for example)

1. Next, let's change directory to the new workspace and run a Terraform plan to see what happens:

    ```sh
    cd ../new_workspace/
    ```
    ```hcl
    terraform init
    terraform plan

    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
        + create

    Terraform will perform the following actions:

        # aws_security_group.base will be created
        + resource "aws_security_group" "base" {
    ```

    Terraform will attempt to create the resource because although we've imported the resource configuration code, we haven't imported it into the workspace state yet.

1. We'll now import the knowledge of the resource into the workspace state. This will let workspace know to manage the resource from now on. The syntax of the command is terraform import [address] [resourceid]

    ```hcl
    terraform import aws_security_group.base sg-000b5f84a61683d8f

    Import successful!

    The resources that were imported are shown above. These resources are now in your Terraform state and will henceforth be managed by Terraform.
    ```

    Verify with a `terraform state list` command:

    ```hcl
    terraform state list

    aws_security_group.base
    ```
    If we run a plan, Terraform no longer wants to create the resource because it knows it already exists:

    ```hcl
    terraform init
    terraform plan

    aws_security_group.base: Refreshing state... [id=sg-000b5f84a61683d8f]

    No changes. Your infrastructure matches the configuration.
    ```

1. Once successful, we can remove the resource from the old workspace

    ```sh
    cd ../old_workspace/
    ```
    ```hcl
    terraform state rm aws_security_group.base

    Removed aws_security_group.base
    Successfully removed 1 resource instance(s).
    ```

    We can verify with the `terraform state list` or `terraform init` & `terraform plan` commands to illustrate that the old workspace no longer manages the resource(s)

    ```hcl
    No changes. Your infrastructure matches the configuration.

    Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
    ```

## Cleanup

1. Run `terraform destroy` within each workspace directory

    ```hcl
    terraform init
    terraform destroy --auto-approve

    aws_security_group.base: Destruction complete after 1s

    Apply complete! Resources: 0 added, 0 changed, 1 destroyed.
    ```