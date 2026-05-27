FROM golang:1.22-alpine AS builder

WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server ./cmd

FROM alpine:3.20

RUN adduser -D -g '' appuser
WORKDIR /app
COPY --from=builder /app/server ./server

ENV PORT=8080
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}
EXPOSE 8080

USER appuser
CMD ["./server"]
