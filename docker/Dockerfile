FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy dependency files first (for Docker layer caching)
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install --omit=optional --no-audit --no-fund

# Copy the rest of the project
COPY . .

# Ensure entrypoint is executable
RUN chmod +x ./docker/entrypoint.sh

# Compile + deploy at container startup
CMD ["sh", "./docker/entrypoint.sh"]
