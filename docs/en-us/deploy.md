*Thanks to [BARK](https://github.com/Finb/Bark) for the open source project*

## Docker-Compose 
* Configuration

```yaml
system: # System configuration
  name: "pushback" # Service name
  user: "" # Service username
  password: "" # Service password
  address: "0.0.0.0:8080" # Service listening address
  debug: false # Enable debug mode
  dsn: "" # mysql user:password@tcp(host:port)
  maxApnsClientCount: 1 # Maximum APNs client connections

apple: # Apple push notification configuration
  keyId: "BNY5GUGV38" # Key ID
  teamId: "FUWV6U942Q" # Team ID
  topic: "me.uuneo.Meoworld" # Push topic
  develop: false # Development environment
  apnsPrivateKey: |- # APNs private key
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgvjopbchDpzJNojnc
    o7ErdZQFZM7Qxho6m61gqZuGVRigCgYIKoZIzj0DAQehRANCAAQ8ReU0fBNg+sA+
    ZdDf3w+8FRQxFBKSD/Opt7n3tmtnmnl9Vrtw/nUXX4ldasxA2gErXR4YbEL9Z+uJ
    REJP/5bp
    -----END PRIVATE KEY-----
  adminId: "" # Admin ID

```

### Command Line Parameters

In addition to the configuration file, you can also configure the service through command line parameters or environment variables:

| Parameter | Environment Variable | Description | Default Value |
|-----------|---------------------|-------------|---------------|
| `--addr` | `PB_SERVER_ADDR` | Server listening address | empty |
| `--config`, `-c` | `PB_SERVER_CONFIG` | Configuration file path | `/data/config.yaml` |
| `--dsn` | `PB_SERVER_DSN` | MySQL DSN | empty |
| `--maxApnsClientCount`, `-max` | `PB_MAX_APNS_CLIENT_COUNT` | Maximum APNs client count | 0 (unlimited) |
| `--debug` | `PB_DEBUG` | Enable debug mode | false |
| `--develop`, `-dev` | `PB_DEVELOP` | Enable push development mode | false |
| `--user`, `-u` | `PB_USER` | Server username | empty |
| `--password`, `-p` | `PB_PASSWORD` | Server password | empty |

Command line parameters take precedence over configuration file settings, and environment variables take precedence over command line parameters.

## Docker Deployment

```shell
docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  sanvx/pushback:latest
```

## Docker-compose Deployment
* Copy the `/deploy` folder from the project to your server, then execute the following command.
* Optionally configure `config.yaml` file, you can modify the configuration items according to your needs.

* Start
```shell
docker-compose up -d
```

## Manual Deployment

1. Download the executable file according to your platform:<br> <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a><br>
or compile it yourself<br>
<a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. Run
---
```
./main
```

## Additional Information

1. The APP is responsible for sending the <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a> to the server. <br>When the server receives a push request, it will send the push to Apple's servers. Then the phone will receive the push notification.

2. Server code: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. App code: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>

