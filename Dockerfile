FROM alpine:3.8

RUN apk -U add git
RUN git config --global user.email "pedrofredsilva@gmail.com" && git config --global user.name "Fred Silva"
