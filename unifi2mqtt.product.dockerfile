FROM --platform=$BUILDPLATFORM swift:latest AS builder
WORKDIR /swift
COPY . .
RUN swift build -c release
RUN chmod -R u+rwX,go+rX-w /swift/.build/release/

FROM swift:slim
WORKDIR /unifi2mqtt
ENV PATH="$PATH:/unifi2mqtt"
COPY --from=builder /swift/.build/release/unifi2mqtt .
CMD ["unifi2mqtt"]

# create your own docker image:
#
# docker build . --file unifi2mqtt.product.dockerfile --tag unifi2mqtt
# docker run --name unifi2mqtt unifi2mqtt


# following lines are for publishing on docker hub
#
# docker build . --file unifi2mqtt.product.dockerfile --tag jollyjinx/unifi2mqtt:latest && docker push jollyjinx/unifi2mqtt:latest
# docker tag jollyjinx/unifi2mqtt:development jollyjinx/unifi2mqtt:latest  && docker push jollyjinx/unifi2mqtt:latest
# docker tag jollyjinx/unifi2mqtt:development jollyjinx/unifi2mqtt:3.1.1  && docker push jollyjinx/unifi2mqtt:3.1.1


# multiarch build:
# rm -rf .build/
# version=development
# docker buildx create --use --name multiarch-builder
# docker buildx inspect --bootstrap
# docker buildx build --no-cache --platform linux/amd64,linux/arm64 --tag "jollyjinx/unifi2mqtt:$version" --file unifi2mqtt.product.dockerfile --push .
# docker buildx imagetools inspect "jollyjinx/unifi2mqtt:$version"
