# Use nginx alpine-slim for a lightweight and more secure image
FROM nginx:alpine-slim

# Build arguments for dynamic metadata
ARG BUILD_DATE
ARG VERSION

# Metadata labels (OCI standard)
LABEL org.opencontainers.image.title="My Mind" \
      org.opencontainers.image.description="Mind mapping web application - A free web app for creating and managing mind maps" \
      org.opencontainers.image.source="https://github.com/ondras/my-mind" \
      org.opencontainers.image.url="https://github.com/ondras/my-mind" \
      org.opencontainers.image.documentation="https://github.com/ondras/my-mind/wiki" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Ondřej Žára" \
      org.opencontainers.image.base.name="docker.io/library/nginx:alpine-slim" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}"

# Update packages to fix known vulnerabilities (HIGH: CVE-2026-25646)
RUN apk update && \
    apk upgrade --no-cache libpng && \
    rm -rf /var/cache/apk/*

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy the my-mind application files
COPY my-mind-master/ /usr/share/nginx/html/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Configure permissions for nginx user (already exists in base image)
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run /var/log/nginx && \
    chmod -R 755 /usr/share/nginx/html && \
    touch /run/nginx.pid && \
    chown nginx:nginx /run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port 8080 (non-privileged port for non-root user)
EXPOSE 8080

# Health check (using port 8080)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
