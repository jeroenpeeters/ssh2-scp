FROM node:5

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY examples/package.json /usr/src/app/
RUN npm install
COPY examples /usr/src/app
COPY lib /usr/src/lib

CMD [ "npm", "start" ]

EXPOSE 2222
