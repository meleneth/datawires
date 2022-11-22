# build environment
FROM node:18-bullseye as build
WORKDIR /app
RUN apt-get install python3
COPY package.json package.json
RUN yarn
COPY . .
RUN yarn build

# production environment
FROM nginx:latest
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
