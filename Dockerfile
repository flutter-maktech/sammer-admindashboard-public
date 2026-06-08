FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy the pre-built Flutter web files
COPY . /usr/share/nginx/html

# Remove Dockerfile and nginx.conf from web directory (not needed there)
RUN rm -f /usr/share/nginx/html/Dockerfile

# Copy the custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 3000

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
