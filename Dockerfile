FROM nimlang/nim:2.2.0-alpine-regular as nim
LABEL maintainer="setenforce@protonmail.com"

RUN apk --no-cache add libsass-dev pcre

WORKDIR /src/nitter

COPY nitter.nimble .
RUN nimble install -y --depsOnly

COPY . .
RUN nimble build -d:danger -d:lto -d:strip --mm:refc \
    && nimble scss \
    && nimble md

# ========================
# FINAL STAGE STARTS HERE
# ========================
FROM alpine:latest
WORKDIR /src/
RUN apk --no-cache add pcre ca-certificates

# Copy built binary and files from builder
COPY --from=nim /src/nitter/nitter ./nitter
COPY --from=nim /src/nitter/nitter.example.conf ./nitter.conf
COPY --from=nim /src/nitter/public ./public

# ✅ Copy your sessions.jsonl into the container
COPY src/sessions.jsonl ./sessions.jsonl

EXPOSE 8080
RUN adduser -h /src/ -D -s /bin/sh nitter
USER nitter
CMD ./nitter
