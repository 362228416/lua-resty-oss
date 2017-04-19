--
-- Aliyun oss lua sdk
-- User: LinChao
-- Date: 2017/4/18
-- Time: 下午 5:24

local http = require "resty.http"

local _M = {
    __version = "0.01"
}

local mt = {__index = _M}

function new(oss_config)
    return setmetatable(oss_config, mt)
end

function put_object(self, content, content_type, object_name)
    local headers, err  = self:_build_auth_headers('PUT', content, content_type, object_name)
    local url     = "http://" .. headers['Host'] .. '/' .. object_name
    if err then return nil, err end
    local res, err = self:_send_http_request(url, "PUT", headers, content)
    if not res then
        err	= err or ''
        return nil, nil .. err
    end
    return 	url, object_name, res.body
end

function delete_object(self, object_name)
    local headers, err = self:_build_auth_headers('DELETE', nil, nil, object_name)
    local url = "http://" .. headers['Host'] .. '/' .. object_name
    if err then return nil, err end
    local res, err = self:_send_http_request(url, "DELETE", headers)
    if 204 ~= res.status then
        ngx.log(ngx.ERR, res.body, err)
        return false, res.status
    end
    return true
end

function put_bucket(self, bucket)
    self.bucket = bucket
    local headers, err  = self:_build_auth_headers('PUT')
    local url     = "http://" .. headers['Host'] .. '/'
    if err then return nil, err end
    local res, err = self:_send_http_request(url, "PUT", headers)
    if not res then
        return false, err
    end
    return 	true, nil, res.body
end

function put_bucket_acl(self, bucket, acl)
    local current_bucket = self.bucket
    self.bucket = bucket
    local headers, err  = self:_build_auth_headers('PUT', '', '', '', acl)
    self.bucket = current_bucket
    local url     = "http://" .. headers['Host'] .. '/'
    if err then return nil, err end
    local res, err = self:_send_http_request(url, "PUT", headers)
    if not res then
        return false, err
    end
    return 	true, nil, res.body
end

function delete_bucket(self, bucket)
    local current_bucket = self.bucket
    self.bucket = bucket
    local headers, err  = self:_build_auth_headers('DELETE')
    self.bucket = current_bucket
    local url     = "http://" .. headers['Host'] .. '/'
    if err then return nil, err end
    local res, err = self:_send_http_request(url, "DELETE", headers)
    if not res then
        return false, err
    end
    return 	true, nil, res.body
end

function _sign(self, str)
    local key = ngx.encode_base64(ngx.hmac_sha1(self.secretKey, str))
    return 'OSS '.. self.accessKey .. ':' .. key
end

function _send_http_request(self, url, method, headers, body)
    local httpc = http.new()
    httpc:set_timeout(30000)
    local res, err = httpc:request_uri(url, {
        method = method,
        headers = headers,
        body = body
    })
    httpc:set_keepalive(30000, 10)
    return res, err
end

function _build_auth_headers(self, verb, content, content_type, object_name, acl)
    local bucket            =   self.bucket
    local endpoint          =   self.endpoint
    local bucket_host       =   bucket .. "." .. endpoint
    local Date              =   ngx.http_time(ngx.time())
    local acl               =   acl or 'public-read'
    local aclName           =   "x-oss-acl"
    local MD5               =   ngx.encode_base64(ngx.md5_bin(content))
    local _content_type     =   content_type or  "application/octet-stream"
    local amz               =   "\n" .. aclName .. ":" ..acl
    local resource          =   '/' .. bucket .. '/' .. (object_name or '')
    local CL                =   string.char(10)
    local check_param       =   verb .. CL .. MD5 .. CL .. _content_type .. CL .. Date .. amz .. CL .. resource
    local headers  =	{
        ['Date']            =	Date,
        ['Content-MD5']		=	MD5,
        ['Content-Type']	=	_content_type,
        ['Authorization']	=	self:_sign(check_param),
        ['Connection']		=	'keep-alive',
        ['Host']            =   bucket_host
    }
    headers[aclName]		=	acl
    return headers
end

-- public
_M.new = new
_M.put_object = put_object
_M.delete_object = delete_object
_M.put_bucket = put_bucket
_M.put_bucket_acl = put_bucket_acl
_M.delete_bucket = delete_bucket

-- private
_M._build_auth_headers = _build_auth_headers
_M._send_http_request = _send_http_request
_M._sign = _sign

return _M
