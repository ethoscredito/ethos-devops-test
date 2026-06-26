FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="ethos-mock" \
      org.opencontainers.image.description="EthosPay mock app for EC2 deployment test" \
      com.ethospay.service="ethos-mock" \
      com.ethospay.port="8081"

COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8081/health || exit 1
