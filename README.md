# NCD Twilio simulator

This project is an IVR stress test tool for Surveda (related issue: [instedd/surveda#1793](https://github.com/instedd/surveda/issues/1793)).

The main difference between this project and its ancestor is that instead of a background service to simulate SMS answers, it will take the shape of a Web API to Simuate phone call answers.

It mocks the following Twilio endpoints used by Verboice:

1. [Fetch an IncomingPhoneNumber resource](https://www.twilio.com/docs/phone-numbers/api/incomingphonenumber-resource#fetch-an-incomingphonenumber-resource)
2. [Initiate an outbound call with Twilio](https://www.twilio.com/docs/voice/make-calls#initiate-an-outbound-call-with-twilio)

## Usage (dev path)

Pre-requisites:
  - [docker-dev](https://github.com/waj/dockerdev#run) is running

1. Run `twilisim`:

```bash
docker-compose up web
```

2. Your endpoint is <http://web.ncd_twilio_simulator.lvh.me/>

3. Run `ngrok` if needed:

```bash
docker-compose -d up ngrok
```

4. Your public endpoint is listed [here](http://ngrok.ncd_twilio_simulator.lvh.me/).

5. Follow the end-user usage path (starting at point 6) to set up your channel in Verboice.

## Usage (end-user path)

1. Pick a port number (in this example: 8081)

2. Run:

```bash
docker run --rm -t -i -p 8081:80 instedd/twiliosim
```

3. Your endpoint is: <http://localhost:8081/>

4. Expose your endpoint publicly using [ngrok](https://ngrok.com/docs#getting-started-expose) or similar if needed.

```bash
ngrok http 8081
```

5. Your public endpoint is listed [here](http://127.0.0.1:4040/).

6. Copy your `https` URL:

![ngrok URL](https://user-images.githubusercontent.com/39921597/99557501-88692e00-29a1-11eb-92c5-d27be72885e4.png)

7. Go to your Verboice instance and create a new Twilio Channel using your public endpoint as your channel base URL:

![channel base URL](https://user-images.githubusercontent.com/39921597/99560107-442b5d00-29a4-11eb-9f74-e105961b22d5.png)

## Behaviour

This App was born inspired by the [NCD local gateway simulator](https://github.com/instedd/ncd_local_gateway_simulator), a SMS stress test tool for Surveda. So its expected behaviour is similar to [this one](https://github.com/instedd/ncd_local_gateway_simulator#behaviour).

Every Surveda TTS question is translated by Verboice to a TTS message. For each message received from Verboice, the following rules apply:

| Input | Reply |
|-|-|
| `#hangup` | hang up |
| `#oneof:N,M,O` | one of the the following numbers: `N`, `M` or `O` |
| `#numeric:N-M` | a number between `N` and `M` (including them) |

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
