FROM node:20-bullseye-slim AS builder
WORKDIR /app

# install deps
COPY package*.json ./
RUN apt-get update && apt-get install -y python3 build-essential ca-certificates --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& (npm ci --prefer-offline --no-audit --no-fund || npm install --no-audit --no-fund)

# copy sources and build
COPY . .
RUN npm run build:prod

### production image
FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html

# custom nginx conf to support SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
