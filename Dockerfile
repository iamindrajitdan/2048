# Use official Nginx as base image
FROM nginx:alpine

# Copy game files into nginx html directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]