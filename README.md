# dit4c-imageserver-swift

A DIT4C image server using OpenStack Swift as the backend.

[nginx][nginx] proxies all requests to OpenStack Swift object storage, using a token which is regularly updated and templated into the nginx config using [confd][confd]. [s6][s6] keeps confd and nginx running.

## Running

```
$ rkt trust --root http://dit4c.github.io/release-signing-key.asc
$ rkt --dns=8.8.8.8 run \
  --volume tls,kind=host,source=/etc/tls,readOnly=true \
  https://github.com/dit4c/dit4c-imageserver-swift/releases/download/0.1.1/dit4c-imageserver-swift.linux.amd64.aci \
  --set-env-file /etc/dit4c-imageserver.env \
  --port https:443 \
  --mount volume=tls,target=/tls
```

`dit4c-imageserver.env` example:
```
PORTAL_URI=https://dit4c.example
OS_AUTH_URL=https://keystone-server.example:5000/v2.0/
OS_TENANT_NAME=DIT4CBots
OS_USERNAME=DIT4CBots_prod_imageserver
OS_PASSWORD=myopenstackpassword
SWIFT_CONTAINER_URL=https://swift-server:8888/v1/AUTH_38595da52345e183057c53997af6306f/dit4c.example-private-images
TLS_CERT=/tls/server.crt
TLS_KEY=/tls/server.key
```

[s6]: https://skarnet.org/software/s6/
[confd]: https://github.com/kelseyhightower/confd
[nginx]: https://nginx.org/en/
