# 使用 php:7.4-fpm-alpine 作为基础镜像
FROM php:7.4-fpm-alpine

# 更新包索引并安装 nginx 和其他必要工具
RUN apk --no-cache update && \
    apk --no-cache add nginx supervisor bash && \
    docker-php-ext-install bcmath

# 创建必要的目录结构
RUN mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /etc/supervisor.d && \
    mkdir -p /var/www/html

# 复制当前目录
COPY . /var/www/html/

# 配置 nginx 的默认配置，并将日志重定向到标准输出和标准错误
RUN printf "server {\n\
    listen 80;\n\
    server_name localhost;\n\
    root /var/www/html;\n\
    index index.php index.html index.htm;\n\
    \n\
    location / {\n\
    try_files \$uri \$uri/ =404;\n\
    }\n\
    \n\
    location ~ \\.php$ {\n\
    include fastcgi_params;\n\
    fastcgi_pass 127.0.0.1:9000;\n\
    fastcgi_index index.php;\n\
    fastcgi_param SCRIPT_FILENAME /var/www/html\$fastcgi_script_name;\n\
    }\n\
    }" > /etc/nginx/http.d/default.conf

# 配置 nginx 访问日志和错误日志输出到 stdout 和 stderr
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# 配置 supervisor 来管理 php-fpm 和 nginx
RUN printf '[supervisord]\n\
    nodaemon=true\n\
    \n\
    [program:nginx]\n\
    command=/usr/sbin/nginx -g "daemon off;"\n\
    stdout_logfile=/dev/stdout\n\
    stdout_logfile_maxbytes=0\n\
    stderr_logfile=/dev/stderr\n\
    stderr_logfile_maxbytes=0\n\
    autorestart=true\n\
    \n\
    [program:php-fpm]\n\
    command=docker-php-entrypoint php-fpm\n\
    stdout_logfile=/dev/stdout\n\
    stdout_logfile_maxbytes=0\n\
    stderr_logfile=/dev/stderr\n\
    stderr_logfile_maxbytes=0\n\
    autorestart=true\n' > /etc/supervisor.d/supervisord.ini

# 设置工作目录
WORKDIR /var/www/html

# 启动 supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
