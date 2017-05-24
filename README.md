# 2-way HTTPS Sample

Sample project showing how to do 2-way client/server auth with.

A few ways of running things, but easiest thing is to run the following commands in 2 terminals:

* Terminal 1: `./run-nginx.sh`
* Terminal 2: `curl -k -E certs/client.p12:123123 -v -H 'Host: example.com' https://example.com:8443/`

> Note, you'll need to map `127.0.0.1` to `example.com` in your `/etc/hosts` file (or equivalent for your OS).

You can also run `java-client/src/main/java/com/cloudbees/tftwoway/Client.java` instead of using the `curl` command as above.