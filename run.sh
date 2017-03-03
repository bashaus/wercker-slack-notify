#!/bin/bash

# Property: webhook-url
# Check if Slack webhook URL is present
if [ -z "$WERCKER_SLACK_NOTIFY_WEBHOOK_URL" ]; then
  fail "Property webhook-url must be defined"
fi

# Property: message-channel
# Check if a '#' was supplied in the channel name
if [ "${WERCKER_SLACK_NOTIFY_MESSAGE_CHANNEL:0:1}" = "#" ]; then
  WERCKER_SLACK_NOTIFY_MESSAGE_CHANNEL="${WERCKER_SLACK_NOTIFY_MESSAGE_CHANNEL:1}"
fi

# Property: message-on-failed
# Must be a valid boolean (true, false, 1 or 0)
case "$WERCKER_SLACK_NOTIFY_MESSAGE_ON_FAILED" in
  "true" | "1" ) WERCKER_SLACK_NOTIFY_MESSAGE_ON_FAILED="1" ;;
  "false" | "0" ) WERCKER_SLACK_NOTIFY_MESSAGE_ON_FAILED="0" ;;
  * ) fail "Property message-on-failed must be either true or false"
esac

# If false, do not message the user on failed
if [ "$WERCKER_RESULT" = "failed" ]; then
  if [ "$WERCKER_SLACK_NOTIFY_MESSAGE_ON_FAILED" = "0" ]; then
    info "Build failed: no notification sent: property message-on-failed is false"
    return 0
  fi

  WERCKER_SLACK_NOTIFY_MESSAGE_COLOR="danger"
fi

# Property: message-on-passed
# Must be a valid boolean (true, false, 1 or 0)
case "$WERCKER_SLACK_NOTIFY_MESSAGE_ON_PASSED" in
  "true" | "1" ) WERCKER_SLACK_NOTIFY_MESSAGE_ON_PASSED="1" ;;
  "false" | "0" ) WERCKER_SLACK_NOTIFY_MESSAGE_ON_PASSED="0" ;;
  * ) fail "Property message-on-passed must be either true or false"
esac

# If false, do not message the user on passed
if [ "$WERCKER_RESULT" != "failed" ]; then
  if [ "$WERCKER_SLACK_NOTIFY_MESSAGE_ON_PASSED" = "0" ]; then
    info "Build passed: no notification sent: property message-on-passed is false"
    return 0
  fi

  WERCKER_SLACK_NOTIFY_MESSAGE_COLOR="good"
fi

# Helper: WERCKER_SLACK_NOTIFY_RUN_URL
# For old builds, there is no $WERCKER_RUN_URL, so use the
# WERCKER_APPLICATION_URL instead
if [ -n "$WERCKER_RUN_URL" ]; then
  WERCKER_SLACK_NOTIFY_RUN_URL="$WERCKER_RUN_URL"
elif [ -n "$WERCKER_APPLICATION_URL" ]; then
  WERCKER_SLACK_NOTIFY_RUN_URL="$WERCKER_APPLICATION_URL"
else
  WERCKER_SLACK_NOTIFY_RUN_URL="https://app.wercker.com/"
fi

# Helper: WERCKER_SLACK_NOTIFY_COMMIT_URL
# Build the URL of the commit which can be viewed in a browser
case "$WERCKER_GIT_DOMAIN" in
  "bitbucket.org" )
    WERCKER_SLACK_NOTIFY_REPOSITORY_URL="https://bitbucket.org/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY"
    WERCKER_SLACK_NOTIFY_COMMIT_URL="$WERCKER_SLACK_NOTIFY_REPOSITORY_URL/commits/$WERCKER_GIT_COMMIT"
    ;;

  "github.com" )
    WERCKER_SLACK_NOTIFY_REPOSITORY_URL="https://github.com/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY"
    WERCKER_SLACK_NOTIFY_COMMIT_URL="$WERCKER_SLACK_NOTIFY_REPOSITORY_URL/commit/$WERCKER_GIT_COMMIT"
    ;;

  * )
    WERCKER_SLACK_NOTIFY_REPOSITORY_URL="$WERCKER_SLACK_NOTIFY_RUN_URL"
    WERCKER_SLACK_NOTIFY_COMMIT_URL="$WERCKER_SLACK_NOTIFY_RUN_URL"
    ;;
esac

# Helper: WERCKER_SLACK_NOTIFY_PIPELINE_NAME
# Identify the name of the Pipeline.
# If this is the first pipeline, then $WERCKER_DEPLOYTARGET_NAME is not set so
# attempt to identify it manually via $WERCKER_RUN_URL
if [ -n "$WERCKER_DEPLOYTARGET_NAME" ]; then
  WERCKER_SLACK_NOTIFY_PIPELINE_NAME="$WERCKER_DEPLOYTARGET_NAME"
elif [[ "$WERCKER_RUN_URL" =~ ^https://app.wercker.com/[^/]+/[^/]+/runs/([^/]+)/.*$ ]]; then
  WERCKER_SLACK_NOTIFY_PIPELINE_NAME="${BASH_REMATCH[1]}"
elif [[ "$WERCKER_RUN_URL" =~ ^https://app.wercker.com/\#[^/]+/[^/]+/([^/]+)/.*$ ]]; then
  WERCKER_SLACK_NOTIFY_PIPELINE_NAME="${BASH_REMATCH[1]}"
else
  WERCKER_SLACK_NOTIFY_PIPELINE_NAME="build"
fi

# Helper: Default pretext and text

# Commit {#a1b2c3d} on branch {master} in repository {hello-world} by {John Doe}
if [ -n $WERCKER_SLACK_NOTIFY_MESSAGE_PRETEXT ]; then
  WERCKER_SLACK_NOTIFY_MESSAGE_PRETEXT="$(
    echo  "Commit <$WERCKER_SLACK_NOTIFY_COMMIT_URL|#${WERCKER_GIT_COMMIT:0:7}>" \
          "on branch $WERCKER_GIT_BRANCH" \
          "in repository <$WERCKER_SLACK_NOTIFY_REPOSITORY_URL|$WERCKER_GIT_REPOSITORY>"
  )"
fi

# Pipeline {build} has passed
if [ -n $WERCKER_SLACK_NOTIFY_MESSAGE_TEXT_ON_PASSED ]; then
  WERCKER_SLACK_NOTIFY_MESSAGE_TEXT_ON_PASSED="$(
    echo  "Pipeline <$WERCKER_SLACK_NOTIFY_RUN_URL|$WERCKER_SLACK_NOTIFY_PIPELINE_NAME>" \
          "has $WERCKER_RESULT"
  )"
fi

# Pipeline {build} has failed at step {node-install}
# {failure message}
if [ -n $WERCKER_SLACK_NOTIFY_MESSAGE_TEXT_ON_FAILED ]; then
  WERCKER_SLACK_NOTIFY_MESSAGE_TEXT_ON_FAILED="$(
    echo  "Pipeline <$WERCKER_SLACK_NOTIFY_RUN_URL|$WERCKER_SLACK_NOTIFY_PIPELINE_NAME>" \
          "has $WERCKER_RESULT" \
          "at step $WERCKER_FAILED_STEP_DISPLAY_NAME:\r\n" \
          "$WERCKER_FAILED_STEP_MESSAGE"
  )"
fi

# Helper: Fallback
# {passed}: {#a1b2c3} at {build-php}
WERCKER_SLACK_NOTIFY_FALLBACK="${WERCKER_GIT_COMMIT:0:7} $WERCKER_RESULT on $WERCKER_SLACK_NOTIFY_PIPELINE_NAME"

# Define the message to build
if [ "$WERCKER_RESULT" = "failed" ]; then
  WERCKER_SLACK_NOTIFY_MESSAGE="$WERCKER_SLACK_NOTIFY_MESSAGE_TEXT_ON_FAILED"
else
  WERCKER_SLACK_NOTIFY_MESSAGE="$WERCKER_SLACK_NOTIFY_MESSAGE_TEXT_ON_PASSED"
fi

# Construct the JSON
WERCKER_SLACK_NOTIFY_JSON="{
  $( [ -n "$WERCKER_SLACK_NOTIFY_MESSAGE_CHANNEL" ] && echo "\"channel\": \"#$WERCKER_SLACK_NOTIFY_MESSAGE_CHANNEL\"," )
  \"unfurl_links\": false,
  \"username\": \"$WERCKER_SLACK_NOTIFY_MESSAGE_USERNAME\",
  \"icon_url\":\"$WERCKER_SLACK_NOTIFY_MESSAGE_ICON_URL\",
  \"attachments\":[
    {
      \"pretext\": \"$WERCKER_SLACK_NOTIFY_MESSAGE_PRETEXT\",
      \"text\": \"$WERCKER_SLACK_NOTIFY_MESSAGE\",
      \"fallback\": \"$WERCKER_SLACK_NOTIFY_FALLBACK\",
      \"color\": \"$WERCKER_SLACK_NOTIFY_MESSAGE_COLOR\",
      \"mrkdwn_in\": [ \"text\", \"pretext\" ]
    }
  ]
}"

# Post the result to the Slack webhook
WERCKER_SLACK_NOTIFY_WEBHOOK_RESULT="$(
  curl  -d "payload=$WERCKER_SLACK_NOTIFY_JSON" \
        -s "$WERCKER_SLACK_NOTIFY_WEBHOOK_URL" \
        --output "$WERCKER_STEP_TEMP"/result.txt \
        -w "%{http_code}"
)"

if [ "$WERCKER_SLACK_NOTIFY_WEBHOOK_RESULT" = "200" ]; then
  success $(cat "$WERCKER_STEP_TEMP/result.txt")
else
  fail $(cat "$WERCKER_STEP_TEMP/result.txt")
fi
