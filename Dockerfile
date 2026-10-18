FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS build

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
ARG REVISION=unknown
ARG BRANCH=unknown
ARG BUILD_DATE=unknown

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -tags netgo \
      -ldflags "-s -w \
        -X github.com/prometheus/common/version.Version=${VERSION} \
        -X github.com/prometheus/common/version.Revision=${REVISION} \
        -X github.com/prometheus/common/version.Branch=${BRANCH} \
        -X github.com/prometheus/common/version.BuildUser=docker \
        -X github.com/prometheus/common/version.BuildDate=${BUILD_DATE}" \
      -o /out/govc_exporter .

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/govc_exporter /bin/govc_exporter

EXPOSE     9752
USER       nonroot
ENTRYPOINT ["/bin/govc_exporter"]
