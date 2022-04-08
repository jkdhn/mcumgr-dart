## 0.0.1

* Basic support for device firmware upgrades

## 0.0.2

* Added documentation
* Added echo command
* Made the chunkSize parameter of uploadImage optional (defaults to 128)

## 0.0.3

* Client only subscribes to the input stream once
* Added close() to Client
* Added windowSize to uploadImage to send multiple chunks at once (defaults to 3, set to 1 to disable)
