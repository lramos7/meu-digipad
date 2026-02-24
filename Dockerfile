FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    build-base

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "server:prod"]
