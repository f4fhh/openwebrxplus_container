
# openwebrxplus_container
Docker container for OpenwebRX+ web sdr on SDRPlay and RTL-SDR devices

It works with compatible devices including:
* Any SDRPLAY RSP device that is supported by SDRPLAY API V3
* Any RTLSDR USB device

### Defaults
* Port 8073/tcp is used for the GUI and is exposed by default

### User Configured
* OPENWEBRX_ADMIN_USER : name of the OpenWebRX+ administrator
* OPENWEBRX_ADMIN_PASSWORD : password of the OpenWebRX+ administrator

#### Example docker run

```
docker run -d \
--restart unless-stopped \
--name='openwebrxplus' \
--device=/dev/bus/usb \
-v /mnt/user/appdata/openwebrxplus:/var/lib/openwebrx
-e OPENWEBRX_ADMIN_USER=admin
-e OPENWEBRX_ADMIN_PASSWORD=admin
ghcr.io/f4fhh/openwebrxplus_container:latest
```
### HISTORY
 - Version 0.1.0: Initial build
 - Version 0.1.1: Updated SoapySDRPlay3
 - Version 0.1.2: Updated OpenWebRX+ to 1.2.20
 - Version 0.1.3: Updated OpenWebRX+ to 1.2.21
 - Version 0.1.4: Updated OpenWebRX+ to 1.2.24

### Credits
 - [SDRPlay](https://github.com/SDRplay) for the SDK of the RSP devices
 - [OpenWebRX+](https://github.com/luarvique/openwebrx) by [Marat Fayzullin](http://fms.komkon.org/)

## Licensing
OpenWebRX+ is available under Affero GPL v3 license
([summary](https://tldrlegal.com/license/gnu-affero-general-public-license-v3-(agpl-3.0))).
