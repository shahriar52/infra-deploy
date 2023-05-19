# Application container deployment with AWS ECS and Jenkins

## Goals
- Build application docker image in Jenkis then push to AWS ECR.
- Deploy the image into an AWS ECS cluster once the build is completed and a new image is ready. 

## Description
The infrastructure code is split into two sections,
- Core infrastructure, such as VPC, NAT Gateway, Internet Gateway, ECR repo, Application load balancers and ECS cluster.
- Application runtime infrastructure such as ECS tasks and services.

The main reason for this split is to isolate application runtime infrastructure from the core so that re-deploying or destroying an application has minimal impact on the core infrastructure which is more or less static.

This repository provides two sets of terraform codes and Jenkins files for the above purpose.

## Procedure
- Clone this repository and import the `infra/Jenkinsfile` file into Jenkins to create the core infrastructure (`Infra`) pipeline. Set the Jenkins parameters and terraform variable in the `infra/variables.tf` file. Run the pipeline to deploy the core infrastructure. This would push the terraform state file back to Git at the end of the pipeline.
- Once the above is successfully deployed check the `app_deploy/variables.tf` to import some of the resource information from the core infrastructure.
- Apply the `app_deploy/Jenkinsfile` to create the Jenkins pipeline (`Build and Deploy`) for the application build and deployment.
- Set the application code repository alone with other Jenkins pipeline parameters and run the `Build and Deploy` pipeline. This would build the application from the Dockerfile, push the image with proper tagging into the previously build ECR image repository and then run Terraform to deploy the ECR task and service associated with the application. Terraform state file is pushed to Git at the end.
- If the application changes in the application code repo, running the `Build and Deploy` pipeline again would reconcile new code into the cluster in a Blue-Green fashion.

## Improvements

This is a bare minimum solution. Various improvements can be done to make it more robust.
- Trigger the `Build and Deploy` pipeline when a new code is pushed to Git.
- Application branching model can easily be achieved with a few conditionals applied into the `app_deploy/Jenkinsfile` such that if the code is built from the development Git branch of the application it would auto-pick the development ECS cluster to deploy it.