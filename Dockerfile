FROM crystallang/crystal:0.35.1

ADD . /src
RUN \
  cd /src && \
  shards build --release --no-debug && \
  mv bin/twiliosim /usr/bin/twiliosim

ENV PORT=80

CMD /usr/bin/twiliosim

EXPOSE 80
