# lua-resty-oss
阿里云oss lua sdk，基于openresty

使用方法
```lua

local oss = require "resty.oss"

local oss_config = {
    accessKey	  =   "your accessKey";
    secretKey	  =   "your secretKey";
    bucket      =   "your bucket",
    endpoint    =   "your oss endpoint" -- 例如：oss-cn-qingdao.aliyuncs.com
}

local client = oss.new(oss_config)
local url = client:put_object("123", "text/html", "123.json")
ngx.say(url)
client:delete_object('123.json')

client:put_bucket('test-bucket123')
client:put_bucket_acl('test-bucket123', 'private')
client:put_bucket_acl('test-bucket123', 'public-read')
client:delete_bucket('test-bucket123')

```

上面的例子是直接上传文件并指定内容，文件类型，文件名

真实场景，可能是客户端上传一个文件，然后在nginx获取到文件的内容，文件类型，然后自动生成一个文件名，再调用上面的put_object方法进行上传

文件上传模块可以用[lua-resty-upload](https://github.com/openresty/lua-resty-upload)来处理

lua代码参考:
```lua

local upload = require "resty.upload"
local oss = require "resty.oss"

-- 获取上传的文件
function readFile()
    local chunk_size = 4096
    local form, err = upload:new(chunk_size)
    form:set_timeout(20000)
    local file = {}
    if not err then
        while true do
            local typ, res, err2 = form:read()
            if not typ then
                err = err2
                print("failed to read: ", err2)
                break
            end
            if typ == 'header' and res[1] == 'Content-Disposition' then
                local filename = string.match(res[2], 'filename="(.*)"')
                file.name = filename
            end
            if typ == 'header' and res[1] == 'Content-Type' then
                file['type'] = res[2]
            end
            if typ == 'body' and file then
                file[typ] = (file[typ] or '') .. res
            end
            if typ == "eof" then
                break
            end
        end
    end
    return file, err
end

local file, err = readFile()

local oss_config = {
    accessKey	  =   "your accessKey";
    secretKey	  =   "your secretKey";
    bucket      =   "your bucket",
    endpoint    =   "your oss endpoint" -- 例如：oss-cn-qingdao.aliyuncs.com
}

local client = oss.new(oss_config)
local url = client:put_object(file.body, file.type, file.name)
ngx.say(url)
```

前端代码参考
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Upload</title>
</head>
<body>
<input id="fileupload" type="file"/>
<script type="text/javascript" src="https://cdn.staticfile.org/jquery/1.11.1/jquery.min.js"></script>
<script type="text/javascript" src="http://blueimp.github.io/jQuery-File-Upload/js/vendor/jquery.ui.widget.js"></script>
<script type="text/javascript" src="http://blueimp.github.io/jQuery-File-Upload/js/jquery.fileupload.js"></script>
<script type="text/javascript">

    var url = '/hello';
    $('#fileupload').fileupload({
        url: url,
        dataType: 'text',
        done: function (e, data) {
            console.log('succcess', data);
        },
        progressall: function (e, data) {
            console.log(data);
        }
    })
</script>
</body>
</html>
```

## 已实现方法

* put_object        上传文件
* delete_object     删除文件
* put_bucket        创建bucket
* put_bucket_acl    修改bucket权限
* delete_bucket     删除bucket

## TODO
完整实现所有api，参考[阿里云OSS API文档](http://doc.oss.aliyuncs.com/)

基本功能是没有问题的，欢迎使用

如果你觉得不错，并在项目中使用到它，还可以向我捐献，鼓励鼓励我，金额不限

![微信二维码](https://github.com/362228416/openresty-web-dev/blob/master/wxpay.png?raw=true)
