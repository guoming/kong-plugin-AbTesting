-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")


-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()

-- constructor
function plugin:new()
  plugin.super.new(self, plugin_name)
  
  -- do initialization here, runs in the 'init_by_lua_block', before worker processes are forked

end

---[[ runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  plugin.super.access(self)

  -- your custom code here
  local limit_cookie = plugin_conf.cookie
  local limit_header = plugin_conf.header
  local limit_ip = plugin_conf.ip
  local matched=true 

  -- 客户端Cookie灰度标识
  local client_cookie = ngx.var.cookie_abtesting
  -- 客户端请求的灰度标识
  local client_header = kong.request.get_header("X-abtesting")
  -- 客户端IP
  local client_ip = ngx.req.get_headers()["X-Real-IP"]
  if client_ip == nil then
    client_ip = ngx.req.get_headers()["x_forworded_for"]
  end
  if client_ip == nil then
    client_ip = ngx.var.remote_addr
  end
 
  if(limit_header~=nil) then  
    if(client_header~=nil) then    
      -- 忽略大小写匹配请求头
     matched = ngx.re.match(client_header, limit_header, "joi")
    else
      matched=false;
    end  
  end
  
  if(matched and limit_cookie~=nil) then
    if(client_cookie~=nil) then
    -- 忽略大小写匹配cookie
    matched = ngx.re.match(client_cookie, limit_cookie, "joi")
    else
      matched=false
    end
  end

  if(matched and limit_ip~=nil) then
    if(client_ip~=nil) then
    -- 忽略大小写匹配ip
    matched = ngx.re.match(client_ip, limit_ip, "joi")
    else
      matched=false
    end
  end

  if matched then
    -- 设置upstream
    local ok, err = kong.service.set_upstream(plugin_conf.upstream)
    if not ok then
        kong.log.err(err)
        return
    end
    -- 匹配成功添加特定头部方便监控
    ngx.req.set_header("X-Kong-" .. plugin_name .. "-upstream", plugin_conf.upstream)      
    ngx.req.set_header("X-Kong-" .. plugin_name .. "-limit-ip", limit_ip)
    ngx.req.set_header("X-Kong-" .. plugin_name .. "-limit-header", limit_header)
    ngx.req.set_header("X-Kong-" .. plugin_name .. "-limit-cookie", limit_cookie)  

    ngx.req.set_header("X-Kong-" .. plugin_name .. "-client-ip", client_ip)
    ngx.req.set_header("X-Kong-" .. plugin_name .. "-client-header", client_header)
    ngx.req.set_header("X-Kong-" .. plugin_name .. "-client-cookie", client_cookie)    

    
    ngx.header["X-Kong-" .. plugin_name .. "-upstream"]=plugin_conf.upstream;    
    ngx.header["X-Kong-" .. plugin_name .. "-limit-ip"]=limit_ip;
    ngx.header["X-Kong-" .. plugin_name .. "-limit-header"]=limit_header;
    ngx.header["X-Kong-" .. plugin_name .. "-limit-cookie"]=limit_cookie;

    ngx.header["X-Kong-" .. plugin_name .. "-client-ip"]=client_ip;
    ngx.header["X-Kong-" .. plugin_name .. "-client-header"]=client_header;
    ngx.header["X-Kong-" .. plugin_name .. "-client-cookie"]=client_cookie;

  end    
  
end --]]

-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 1000

-- return our plugin object
return plugin