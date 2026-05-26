# Stage 1: Build the Flutter web project
FROM debian:stable-slim AS build

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa \
    python3 ca-certificates jq \
    && rm -rf /var/lib/apt/lists/*


RUN git clone --depth 1 https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN git config --global --add safe.directory /usr/local/flutter && \
    flutter config --enable-web && \
    flutter precache --web && \
    flutter --disable-analytics

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get


COPY . .


RUN flutter build web --release --no-tree-shake-icons --web-define=APP_VERSION=$(date +%s)


RUN VERSION=$(date +%s) && \
    mv build/web/flutter_bootstrap.js build/web/flutter_bootstrap.v$VERSION.js && \
    sed -i "s/flutter_bootstrap.js/flutter_bootstrap.v$VERSION.js/g" build/web/index.html && \
    if [ -f build/web/main.dart.mjs ]; then \
    mv build/web/main.dart.mjs build/web/main.dart.v$VERSION.mjs && \
    sed -i "s/main.dart.mjs/main.dart.v$VERSION.mjs/g" build/web/flutter_bootstrap.v$VERSION.js; \
    elif [ -f build/web/main.dart.js ]; then \
    mv build/web/main.dart.js build/web/main.dart.v$VERSION.js && \
    sed -i "s/main.dart.js/main.dart.v$VERSION.js/g" build/web/flutter_bootstrap.v$VERSION.js; \
    fi

# Ensure your custom service worker is present in the final build folder
# If it's already in your /web folder, Flutter copies it automatically, 
# but this line ensures it's there if the build process ignored it.
# RUN cp web/custom_service_worker.js build/web/ 2>/dev/null || :
RUN cp web/custom_service_worker.js build/web/flutter_service_worker.js 2>/dev/null || :

# Stage 2: Serve the built web app using Nginx
FROM nginx:alpine

# Remove default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy the built web app from the build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 3000 (Matches your nginx.conf)
EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]