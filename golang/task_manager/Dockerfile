FROM golang
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o main task_manager_db.go models.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
COPY templates ./templates

EXPOSE 8080
CMD [ "./main" ]

