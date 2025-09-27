FROM node:18-alpine
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
HEALTHCHECK CMD node healthcheck.js || exit 1
CMD ["node", "src/server.js"]
