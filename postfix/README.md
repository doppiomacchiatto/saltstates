# Postfix

This supplies multiple modes of operation:

- simple Postfix MTA that can send mails
- with SPF
- with DKIM

See `pillar.example` as a reference.


# Simple
```
cp pillar.example /srv/pillar/postfix.sls
vi /srv/pillar/postfix.sls
vi /srv/pillar/top.sls
salt-call state.apply postfix
```

Test
```
echo 'test' | mail -s 'test' test@felixhummel.de
```

Make sure to check your spam!


## Mapping Unix-Users to custom addresses
See `man 5 generic` and the `generic_map` key in `pillar.example`.

Test
```
sudo -iu monit bash -c "echo 'test' | mail -s 'test monit' test@felixhummel.de"
```


# SPF
Simply add your IP to your DNS SPF record, e.g.
```
v=spf1 mx a include:example.org ip4:1.2.3.4/32 ~all
```
This uses version 1 allowing

- servers set in the MX and A records
- the policy of `example.org`
- the IP address `1.2.3.4`

and then SOFTFAILs for anything else.

When you are happy with the results, change `~all` to `-all`, so it FAILs.

[Wikipedia](https://en.wikipedia.org/wiki/Sender_Policy_Framework) has more on this.

Test:
```
echo 'test' | mail -s 'test SPF' test@felixhummel.de
```

You should see `spf=pass` in `Authentication-Results`.


# DKIM
There are two parts to this:

1. generate a key pair and update your DNS
2. activate the OpenDKIM milter

If you activate this before your DNS changes have propagated, then you will have a bad time.

## Step 1: generate key pair and update your DNS
Note that `mail` in the following is called the `selector`. See the state `opendkim_genkey.sls`
and http://opendkim.org/opendkim-README for more.

Generate the key-pair:
```
salt-call state.apply postfix.opendkim_genkey
```

Get the public key and set it on your DNS server:
```
salt-call file.read /etc/opendkim/keys/felixhummel.de/mail.txt
```

You can get the paths to all public keys:
```
salt-call grains.get dkim:pubkeys
```

Test:
```
$ dig mail._domainkey.felixhummel.de TXT +short
"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC7e1PrmRKNurpX2kr9G4zYlggo58IFDUHWTs+GAYyRhL6SyyKwsLxVFY6Cu7kJS7iBW/obAI6uCmWTJF9G+cgeXZHo8Z3BmtGV2P94KFZmh2yruH1mtypLwQR8v5a5iCS8u+VrBNPcW8aPxAAk5BN29usL5wxVDxhn/M6N8cEigwIDAQAB"
```

## Step 2: activate the OpenDKIM milter
Assure Salt that the DNS record is set and apply:
```
vi /srv/pillar/postfix.sls
# dns_is_set: true

salt-call state.apply postfix
```

Test:
```
echo 'test' | mail -s 'test DKIM' test@felixhummel.de
```

Syslog should show something like this:
```
opendkim[15478]: 4CC4B13DF1D: DKIM-Signature field added (s=mail, d=felixhummel.de)
```

and you should see `dkim=pass` in `Authentication-Results`.


# Logging
```
tail -f /var/log/syslog
```


# Docs
- https://www.c0ffee.net/blog/mail-server-guide
- https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy
