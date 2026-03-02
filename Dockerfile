FROM node:lts
WORKDIR /app
COPY package.json package-lock.json ./
COPY . .
RUN npm i
EXPOSE 6000
CMD ["npm", "run", "dev"]
