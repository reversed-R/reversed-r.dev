FROM node:latest AS builder
WORKDIR /build
COPY . /build
RUN \
  npm install && \
  npm run build

FROM nginx:latest
COPY --from=builder /build/dist /usr/share/nginx/html
COPY ./release/nginx/default.conf /etc/nginx/conf.d

EXPOSE 80
