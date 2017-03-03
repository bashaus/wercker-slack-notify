# Slack Notify

Wercker step to broadcast the result of a pipeline execution to Slack.

## Notes

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Sample Usage

    deploy:
      box: ubuntu:latest
      steps:
        - bashaus/slack-notify:
          webhook-url: $SLACK_WEBHOOK_URL
          message-on-passed: false

&nbsp;

## Dependencies

You will also need to sign up for a Slack Webhook URL specific for your team.
You can [find out more information about Webhooks](https://api.slack.com/incoming-webhooks)
or create a webhook for your team at:
https://{your-team-name}.slack.com/apps/manage/custom-integrations

This step also requires your box to have `curl` installed.

&nbsp;

## Step Properties

### webhook-url (required)

The Slack webhook URL to interface with your slack team. You can obtain a Slack
webhook from: https://{your-team-name}.slack.com/apps/manage/custom-integrations

* Since: `0.0.1`
* Property is: `Required` via a private Environment Variable
* Recommended location: `Application`

&nbsp;

### message-channel

The name of the channel in which messages will appear.

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `wercker`
* `Validation` rules:
  * Must not begin with a `#`

&nbsp;

### message-username

The username of the bot, messages will be received from this user. Does not
have to be a real username in your Slack team.

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `$WERCKER_GIT_REPOSITORY`

&nbsp;

### message-icon-url

The URL of the icon that should be provided alongside the chat message. By
default, this is the Wercker icon.

![Wercker Icon](https://secure.gravatar.com/avatar/a08fc43441db4c2df2cef96e0cc8c045?s=140)

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `https://secure.gravatar.com/avatar/a08fc43441db4c2df2cef96e0cc8c045?s=140`
* `Validation` rules:
  * Must be a valid URL

&nbsp;

### message-on-passed

Boolean as to whether or not a message should be sent if the pipeline passes.
Enable with `1` or disable with `0`.

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `true`
* `Validation` rules:
  * Must be either `true`, `false`, `1` or `0`

&nbsp;

### message-on-failed

Boolean as to whether or not a message should be sent if the pipeline fails.
Enable with `1` or disable with `0`.

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `true`
* `Validation` rules:
  * Must be either `true`, `false`, `1` or `0`

&nbsp;

### message-pretext

The pretext shown before the message. This should usually contain information
about the commit, but not any specific information about the status of
the build.

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `Commit #{commit} on branch {branch} in repository {repository}`

The default value of this message is contrived of some basic environment
information about the commit and the pipeline.

Example:

    Commit #a1b2c3d on branch master in repository hello-world

&nbsp;

### message-text-on-passed

The text that should be used if a pipeline passes.

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `Pipeline {build} has passed`

&nbsp;

### message-text-on-failed

The text that should be used if a pipeline fails.

* Since: `0.0.1`
* Property is: `Optional`
* Recommended location: `Inline`
* Default value is: `Pipeline {build} has failed at step {npm-install}: {message}`

&nbsp;
