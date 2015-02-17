## Slack Timezone Converter

An integration for Slack that converts any time string in a message to all timezones where the team is.

![Screenshot](timezone.png?raw=true "Screenshot")

Currently supports the following formats (with or without leading zeros), but new formats can be added easily:

* 10am
* 10 am
* 10 AM
* 10AM
* 10pm
* 10PM
* 10 pm
* 10 PM
* 10h
* 10H
* 10h30
* 10H30
* 10:30

Any time a string like one of the ones above is found in a message, the integration, running in a server, converts it to all timezones
where the team has at least one member. A message is sent back to the Slack channel with all the conversions and a fancy clock icon
that represents the time. It supports private messages and all channels.

In order to use this integration, the following Ruby libraries are needed:

* date
* json
* slack-rtmapi
* time
* uri

But they can be installed by using `bundle`:

`bundle install`

After all requirements are met, it's just necessary to run the code, passing the Slack token and default timezone (e.g., "PST")
as parameters:

`ruby slack-timezone-converter.rb <Slack token> <default timezone>`

This program runs indefinitely and listens for new messages on the Slack channels. It can be stopped by just stopping the process.

## References

* https://api.slack.com/web#basics
* https://api.slack.com/rtm
* https://github.com/caiosba/slack-rtmapi
