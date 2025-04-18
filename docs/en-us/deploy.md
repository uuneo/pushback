*Thanks to the [BARK](https://github.com/Finb/Bark) open-source project*

## Docker-Compose  
* Configuration  

```yaml  
system:  
  name: "NewBearService"  
  user: ""         # Username (optional)  
  password: ""     # Password (optional)  
  host: "0.0.0.0"  # Service listen address  
  port: "8080"     # Service listen port; must match the port mapping in docker-compose  
  mode: "release"  # debug, release, test  
  dbType: "default" # default, mysql  
  dbPath: "/data"   # Database file storage path  

mysql: # Only valid when dbType: "mysql"  
  host: "localhost"  
  port: "3306"  
  user: "root"  
  password: "root"  

apple: # Copy the configuration from the project; no changes needed unless compiling your own app  
  keyId:  
  teamId:  
  topic:  
  apnsPrivateKey:  

```
## Docker Deployment  

```shell
docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  neouu/pushback:latest
```

## Docker-compose Deployment  
* Copy the `/deploy` folder from the project to the server, then run the following command.  
* You must have the `/data/config.yaml` configuration file, otherwise, the service won't start. You can modify the configuration options in the file based on your needs.

* Start  
```shell  
docker-compose up -d 
```

## Manual Deployment

1. Download the executable file based on your platform:  
   <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a>  
   Or compile it yourself:  
   <a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. Run  
```sh
./binary-file-name -c config.yaml
```
3. You may need to  
```sh
chmod +x binary-file-name
```
Please note that `pushback-server` must be run with a configuration file specified.


## Others

1. The app side is responsible for sending the <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a> to the server. <br>Once the server receives a push request, it will send the push notification to Apple’s server. The phone will then receive the push notification.

2. Server-side code: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. App code: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>
