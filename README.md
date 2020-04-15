
# Kong 部署说明

## 编辑 Kong.conf
``` Shell
dns_resolver=192.168.109.183:8600
plugins=bundled,abtesting
```
## 安装kong 自定义插件

``` Shell
# 插件会安装到 /usr/local/share/lua/5.1/，docker 需要挂载这个目录
luarocks install kong-plugin-abtesting
```

## 安装 postgres 数据库
``` Shell
docker run -d --name kong-database  \
-p 5432:5432 \
-e "POSTGRES_USER=kong" \
-e "POSTGRES_PASSWORD=kong"
-e "POSTGRES_DB=kong" postgres:9.6 
```
## 迁移 kong 数据库至 postgres
``` Shell
docker run --rm  \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=192.168.109.183" \
-e "KONG_PG_USER=kong" \
-e "KONG_PG_PASSWORD=kong" \
-e "KONG_CASSANDRA_CONTACT_POINTS=kong-database"  \
kong:2.0.2-centos  kong migrations bootstrap
```
## 安装Kong
``` Shell
    docker run --name kong
    -e "KONG_PROXY_ACCESS_LOG=/dev/stdout"
    -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout"
    -e "KONG_PROXY_ERROR_LOG=/dev/stderr"
    -e "KONG_ADMIN_ERROR_LOG=/dev/stderr"
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl"
    -e "KONG_DATABASE=postgres"
    -e "KONG_PG_USER=kong"
    -e "KONG_PG_PASSWORD=kong"
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database"
    -e "KONG_PG_HOST=192.168.109.183"
    -e "DNS_RESOLVER=192.168.109.183:8500"
    -e "KONG_LUA_PACKAGE_PATH=/usr/local/custom/?.lua;./?.lua;./?/init.lua;;"    
    -p 8000:8000 -p 8443:8443 -p 8001:8001 -p 8444:8444
    -v /etc/kong.conf:/etc/kong/kong.conf
    -v /usr/local/share/lua/5.1/:/usr/local/custom/
    kong:2.0.2-centos
```

## 安装Kong 管理界面(konga)

``` Shell
docker run -d -p 1337:1337  --name konga pantsel/konga
```


