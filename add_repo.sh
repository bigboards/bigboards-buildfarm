#!/bin/bash
BUILD_SCRIPT=/opt/bb/buildfarm/build.sh
ORG_SLUG="bigboards"

BUILDKITE="7eaec9eae9c59c4a5f07166a0ddd75eb8ea1d785"
GITHUB_USER="bbbaldrick"
GITHUB_PWD="tpBNZWVuLQ2h"

TMP_FILE="/tmp/$(uuid)"

PROJECT_ID=$1
PROJECT_NAME=$2
CONTAINER_ID=$(echo $PROJECT_ID | sed "s/^docker-//")

## Create the git repo
echo "Creating the github repository"
curl -u "${GITHUB_USER}:${GITHUB_PWD}" -X POST "https://api.github.com/orgs/bigboards/repos" \
  -d "{ \
        \"name\": \"${PROJECT_ID}\", \
        \"auto_init\": true, \
        \"private\": false \
      }"


## Create the buildkite pipeline
echo "Creating the buildkite pipeline"
curl -X POST "https://api.buildkite.com/v2/organizations/${ORG_SLUG}/pipelines?access_token=${BUILDKITE}" \
  -o $TMP_FILE \
  -d "{
    \"name\": \"${PROJECT_NAME}\",
    \"slug\": \"${PROJECT_ID}\",
    \"repository\": \"git@github.com:bigboards/${PROJECT_ID}.git\",
    \"provider\": {
      \"id\": \"github\",
      \"settings\": {
        \"publish_commit_status\": true,
        \"build_pull_requests\": true,
        \"build_pull_request_forks\": false,
        \"build_tags\": false,
        \"publish_commit_status_per_step\": false,
        \"repository\": \"bigboards/${PROJECT_ID}\",
        \"trigger_mode\": \"code\"
    }
  },
    \"steps\": [
      {
        \"type\": \"script\",
        \"name\": \"Build x86_64 :docker:\",
        \"command\": \"${BUILD_SCRIPT} ${CONTAINER_ID} \${BUILDKITE_BRANCH}\",
	\"agent_query_rules\": [
           \"arch=x86_64\"
        ]
      },
      {
        \"type\": \"script\",
        \"name\": \"Build armv7l :docker:\",
        \"command\": \"${BUILD_SCRIPT} ${CONTAINER_ID} \${BUILDKITE_BRANCH}\",
	\"agent_query_rules\": [
           \"arch=armv7l\"
        ]
      }
    ]
  }"

## -- Get the web hook
WEBHOOK=$(cat $TMP_FILE |grep webhook | tr -s " " | cut -d " " -f 3)

echo "Creating the webhook"
curl -u "${GITHUB_USER}:${GITHUB_PWD}" -X POST "https://api.github.com/repos/bigboards/${PROJECT_ID}/hooks" \
  -d "{ \
        \"name\": \"web\",
        \"active\": true,
        \"events\": [
          \"push\",
          \"pull_request\",
          \"deployment\"
        ],
        \"config\": {
          \"url\": ${WEBHOOK},
          \"content_type\": \"json\"
      }"

