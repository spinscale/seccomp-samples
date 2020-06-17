# Seccomp samples

This repository contains seccomp examples in crystal and python, that can be
run in a vagrant VM.

## Setting up the Vagrant VM

The VM is based on Debian buster and needs the backports repo for a fresh
version of libseccomp. Simply run

```
vagrant up
```

and everything else happens automatically. This setup shell script also
installs Elasticsearch, Kibana, Auditbeat and Crystal.

### Running the crystal app

SSH into the VM, go to `/vagrant/crystal-seccomp` and run `shards install`
followed by `shards build`. You will end up with a binary under
`/vagrant/crystal-seccomp/bin/webserver`.

This is a simple webserver, that will try to call `/bin/ls` when a request
is retrieved. By default the webserver listens on port 8080.

You can start the webserver with the `-s` option to enable seccomp.

```
./bin/webserver -s
```

You will now receive an exception when a request is sent.

```
./bin/webserver -s -l
```

The above only logs events, but still allows them. You can check via `dmesg`
for logged audit events in that case.



### Running the python app

The python app is similar to the crystal app, having a `-s` switch to enable
seccomp and a `-l` switch to only log seccomp violations. Just run

```
python3 python-seccomp/app.py -s
```

The webserver listens on port 8081 by default.


## Monitoring seccomp violations using the Elastic Stack

The vagrant image comes with Elasticsearch, Kibana and auditbeat installed.
auditbeat will retrieve every seccomp violation and store it in
Elasticsearch.

When logging into kibana, you can select the `[Auditbeat Auditd] Overview
ECS` dashboard, to monitor seccomp violations in real time.

Kibana is also exposed as a forwarded port, so you can just open
http://localhost:5601 on your host to check out the kibana instance.

