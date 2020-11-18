# NCD Twilio simulator

This project is an IVR stress test tool for Surveda (related issue: [instedd/surveda#1793](https://github.com/instedd/surveda/issues/1793)).

The main difference between this project and its ancestor is that instead of a background service to simulate SMS answers, it will take the shape of a Web API to Simuate phone call answers.

It mocks the following Twilio endpoints used by Verboice:

1. [Fetch an IncomingPhoneNumber resource](https://www.twilio.com/docs/phone-numbers/api/incomingphonenumber-resource#fetch-an-incomingphonenumber-resource)
2. [Initiate an outbound call with Twilio](https://www.twilio.com/docs/voice/make-calls#initiate-an-outbound-call-with-twilio)

## Behaviour

This App was born inspired by the [NCD local gateway simulator](https://github.com/instedd/ncd_local_gateway_simulator), a SMS stress test tool for Surveda. So its expected behaviour is similar to [this one](https://github.com/instedd/ncd_local_gateway_simulator#behaviour).

Every Surveda TTS question is translated by Verboice to a TTS message. For each message received from Verboice, the following rules apply:

| Input | Reply |
|-|-|
| `#hangup` | hang up |
| `#oneof:1,3,5` | `1` or `3` or `5` |
| `#numeric:N-M` | a number between `1` and `5` |

If none of these rules apply, the message is ignored.

The following environment variables controls other aspects of the behavior:

| Variable | Default | Description |
|-|-|-|
| `NO_REPLY_PERCENT` | 0.0 | Percent of respondents that don't reply (implemented by hanging up) |
| `DELAY_REPLY_MIN_SECONDS` | 1 | Minimum delay in seconds to reply |
| `DELAY_REPLY_MAX_SECONDS` | 5 | Maximum delay in seconds to reply |
| `INCORRECT_REPLY_PERCENT` | 0.0 | Percent of respondents that reply an incorrect answer |
| `MAX_INCORRECT_REPLY_VALUE` | 99 | Maximum value replied as an incorrect answer |
| `STICKY_RESPONDENTS` | true | If true, once a respondent replies, it will always reply during the same call |
| `DELAY_HANG_UP_SECONDS` | 5 | Delay in seconds to hang up (applying to both the `no reply` condition and the `#hangup` rule) |
