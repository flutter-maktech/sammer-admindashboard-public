# Stage 1: Build the Flutter web app
FROM ubuntu:22.04 AS build

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Clone Flutter stable channel
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter

# Set Flutter in PATH
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable flutter web
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy the app source code
COPY . .

# Get dependencies
RUN flutter pub get

# Build the app
# Use date to set APP_VERSION as was done in nixpacks.toml
RUN flutter build web --release --no-tree-shake-icons --web-define=APP_VERSION=$(date +%s)

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy the build output from the build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy the custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 3000
EXPOSE 3000

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
