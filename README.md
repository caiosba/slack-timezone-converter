## Slack Timezone Converter

An integration for Slack that converts any time string in a message to all timezones where the team is.

![Screenshot](timezone.png?raw=true "Screenshot")

Currently supports any format parsable by [ActiveSupport](http://api.rubyonrails.org/classes/ActiveSupport/TimeWithZone.html).

Monitors any channel it is in for messages that look like they contain a time and responds with local times for all the members 
in the channel.

In order to use this integration, the following Ruby libraries are needed:

* slack-rtmapi
* active\_support
* json

They can be installed by using `bundle`:

`bundle install`

After all requirements are met, it's just necessary to run the code, passing the Slack token as parameter:

`ruby slack-timezone-converter.rb <Slack token> <number of times per line (defaults to 1)> <additional message>`

This program runs indefinitely and listens for new messages on the Slack channels. It can be stopped by just stopping the process.

## TODO

* Correctly identify the format where a dot is the separator between hour and minutes (e.g., "8.30am")

## References

* https://api.slack.com/web#basics
* https://api.slack.com/rtm
* https://github.com/caiosba/slack-rtmapi
