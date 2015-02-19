## Slack Timezone Converter

An integration for Slack that converts any time string in a message to all timezones where the team is.

![Screenshot](timezone.png?raw=true "Screenshot")

Currently supports any format parsable by the [Ruby's Time class](http://ruby-doc.org/stdlib-2.1.1/libdoc/time/rdoc/Time.html#method-c-parse).

Any time a time string is found in a message, the integration, running in a server, converts it to all timezones
where the team has at least one member. A message is sent back to the Slack channel with all the conversions and a fancy clock icon
that represents the time. It supports any channel joined by the user whose token is passed as parameter. This user's timezone is used
as the default when a timezone is not present on the parsed message.

In order to use this integration, the following Ruby libraries are needed:

* slack-rtmapi
* active\_support
* time
* date
* json

But they can be installed by using `bundle`:

`bundle install`

After all requirements are met, it's just necessary to run the code, passing the Slack token as parameter:

`ruby slack-timezone-converter.rb <Slack token> <number of times per line (defaults to 1)>`

This program runs indefinitely and listens for new messages on the Slack channels. It can be stopped by just stopping the process.

## References

* https://api.slack.com/web#basics
* https://api.slack.com/rtm
* https://github.com/caiosba/slack-rtmapi
