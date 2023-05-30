# BUILD IMAGE
FROM crystallang/crystal:1.7-alpine AS build
COPY . /src
RUN cd /src && shards build

# RELEASE IMAGE
FROM alpine:3.16
RUN apk add --no-cache libgcc libxml2 pcre
COPY --from=build /src/bin/twiliosim /usr/bin/twiliosim
ENV PORT=80
EXPOSE 80
CMD /usr/bin/twiliosim
