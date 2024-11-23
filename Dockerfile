# Use the official Node.js 18 image
FROM node:18-alpine

# Set the working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json yarn.lock ./
RUN yarn install

# Copy the rest of the application code
COPY . .

# Build the app
RUN yarn build

# Install the serve package globally to host the app
RUN yarn global add serve

# Expose the app on port 3001
EXPOSE 3001

# Command to run the app
CMD ["serve", "-s", "build", "-l", "3001"]
