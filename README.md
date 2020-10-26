# NCD Twilio simulator

This project will be an IVR stress test tool for Surveda.

Related issue: [instedd/surveda#1793](https://github.com/instedd/surveda/issues/1793)

## Behaviour

This App will be very similar to the [NCD local gateway simulator
](https://github.com/instedd/ncd_local_gateway_simulator), a SMS stress test tool for Surveda.

So its main expected behaviour will be similar to [this one](https://www.twilio.com/docs/phone-numbers/api/incomingphonenumber-resource#fetch-an-incomingphonenumber-resource).

## Web API

The main difference between this project and its ancestor is that instead of a background service it will take the shape of a Web API.

It will mock 2 Twilio API endpoints used by Verboice:

1. [Fetch an IncomingPhoneNumber resource](https://www.twilio.com/docs/phone-numbers/api/incomingphonenumber-resource#fetch-an-incomingphonenumber-resource)
2. [Initiate an outbound call with Twilio](https://www.twilio.com/docs/voice/make-calls#initiate-an-outbound-call-with-twilio)
