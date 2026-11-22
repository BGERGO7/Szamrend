FROM alpine:3.20

RUN apk add --no-cache bash curl

RUN addgroup -S app && adduser -S -G app -h /home/app app

COPY --chown=app:app logtool.sh /app/logtool.sh
RUN chmod 0755 /app/logtool.sh

WORKDIR /app
USER app

ENTRYPOINT ["/app/logtool.sh"]
