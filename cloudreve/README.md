## FAQ

1. 离线下载刚开始就立刻停止。
   1. 检查网络并确认下载目录权限。
   2. 查看日志，若遇到 fallocate failed.cause：Operation not supported 的错误提示则表示内核或者文件系统不支持 fal­loc 文件分配方式，修改配置文件中 file-allocation 选项的参数为 none，重启 Aria2 服务端即可。

2. Windows资源管理器挂载问题。
   1. 无法挂载http地址。修改`\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WebClient\Parameters`将`BasicAuthLevel`的值改为`2`
   2. 无法传输大文件。修改`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WebClient\Parameters`将`FileSizeLimitInBytes`的值改为`ffffffff`
