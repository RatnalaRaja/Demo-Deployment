# === Stage 1: Build React App ===
FROM node:18-alpine AS build

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy all files, including .env
COPY . .

# Build the React app (will read .env here)
RUN npm run build

# === Stage 2: Serve with Nginx ===
FROM nginx:stable-alpine

# Remove default index.html
RUN rm -rf /usr/share/nginx/html/*

# Copy build output to Nginx
COPY --from=build /app/build /usr/share/nginx/html

# Expose port and run
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
