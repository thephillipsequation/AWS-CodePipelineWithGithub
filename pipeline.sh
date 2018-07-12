#!/bin/bash -ex
CFN_TEMPLATE=pipeline.yml
STACK_NAME=user-account-pipeline
AWS_PROFILE=default
GIT_BRANCH=master
GIT_REPO=AWS-User-Account-Creation
AWS_REGION=us-east-1
GIT_OWNER=thephillipsequation

PARAMETERS=" \
  ParameterKey=GitBranch,ParameterValue=${GIT_BRANCH} \
  ParameterKey=GitRepo,ParameterValue=${GIT_REPO} \
  ParameterKey=GitToken,ParameterValue=${GIT_TOKEN} \
  ParameterKey=GithubOwner,ParameterValue=${GIT_OWNER} \
  "

WEBHOOK="{"webhook": 
  {"name": "github-webhook",
   "targetPipeline": "pipeline_name",
   "targetAction": "source_action_name",
   "filters": [
    {
      "jsonPath": "$.ref", 
      "matchEquals": "refs/heads/{Branch}"
    }
   ],
   "authentication": "GITHUB_HMAC",
   "authenticationConfiguration": {"SecretToken":"secret"}
  }
}"

deploy_cfn () {
  if [ $# -gt 0 ]; then
    case "$1" in
      update)
        echo -e "\n\nUpdating ${STACK_NAME} Stack:\n\n"
        aws cloudformation update-stack \
          --profile ${AWS_PROFILE} \
          --region ${AWS_REGION} \
          --stack-name ${STACK_NAME} \
          --capabilities CAPABILITY_NAMED_IAM \
          --template-body file://./${CFN_TEMPLATE} \
          --parameters ${PARAMETERS}
        ;;
      delete)
        echo -e "\n\nDeleting ${STACK_NAME} Stack:\n\n"
        aws cloudformation delete-stack --profile ${AWS_PROFILE} --stack-name ${STACK_NAME}
        ;;
      status)
        echo -e "\n\n${STACK_NAME} Stack:\n\n"
        aws cloudformation describe-stacks --profile ${AWS_PROFILE} --stack-name ${STACK_NAME}
        ;;
      watch)
        watch "aws cloudformation describe-stack-events --profile ${AWS_PROFILE} --stack-name ${STACK_NAME}"
        ;;
      *) echo -e "\n\nValid commands are 'update', 'status', 'watch', or 'delete'\n\n"
        exit 1
        ;;
    esac
  else
    echo -e "\n\nCreating ${STACK_NAME} Stack:\n\n"
    aws cloudformation create-stack \
      --profile ${AWS_PROFILE} \
      --stack-name ${STACK_NAME} \
      --region ${AWS_REGION} \
      --disable-rollback \
      --capabilities CAPABILITY_NAMED_IAM \
      --template-body file://./${CFN_TEMPLATE} \
      --parameters ${PARAMETERS}
  fi
}

deploy_cfn $1