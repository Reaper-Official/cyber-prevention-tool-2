FROM nginx:1.25-alpine
COPY public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
RUN chown -R nginx:nginx /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s CMD wget -q -O /dev/null http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
