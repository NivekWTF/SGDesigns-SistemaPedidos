FROM node:20-bullseye-slim AS builder
WORKDIR /app

# install deps
COPY package*.json ./
RUN apt-get update && apt-get install -y python3 build-essential ca-certificates --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& (npm ci --prefer-offline --no-audit --no-fund || npm install --no-audit --no-fund)

# copy sources and build
COPY . .

# Pass ARGs provided by docker-compose to Vite at build time
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ARG VITE_BUSINESS_NAME
ARG VITE_BUSINESS_RFC
ARG VITE_BUSINESS_EMAIL
ARG VITE_BUSINESS_ADDRESS
ARG VITE_BUSINESS_PHONE
ARG VITE_BUSINESS_LOGO_URL
ARG VITE_BUSINESS_SOCIALS
ARG VITE_BUSINESS_SERIES
ARG VITE_BUSINESS_TAX_RATE

ENV VITE_SUPABASE_URL=$VITE_SUPABASE_URL
ENV VITE_SUPABASE_ANON_KEY=$VITE_SUPABASE_ANON_KEY
ENV VITE_BUSINESS_NAME=$VITE_BUSINESS_NAME
ENV VITE_BUSINESS_RFC=$VITE_BUSINESS_RFC
ENV VITE_BUSINESS_EMAIL=$VITE_BUSINESS_EMAIL
ENV VITE_BUSINESS_ADDRESS=$VITE_BUSINESS_ADDRESS
ENV VITE_BUSINESS_PHONE=$VITE_BUSINESS_PHONE
ENV VITE_BUSINESS_LOGO_URL=$VITE_BUSINESS_LOGO_URL
ENV VITE_BUSINESS_SOCIALS=$VITE_BUSINESS_SOCIALS
ENV VITE_BUSINESS_SERIES=$VITE_BUSINESS_SERIES
ENV VITE_BUSINESS_TAX_RATE=$VITE_BUSINESS_TAX_RATE

RUN npm run build:prod

### production image
FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html

# custom nginx conf to support SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
