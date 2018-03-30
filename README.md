# BOSH release for kafka

This BOSH release and deployment manifest deploy a cluster of kafka.

## Usage

This repository includes base manifests and operator files. They can be used for initial deployments and subsequently used for updating your deployments:

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=kafka
git clone https://github.com/cloudfoundry-community/kafka-boshrelease.git
bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o <(kafka-boshrelease/manifests/operators/pick-from-cloud-config.sh kafka-boshrelease/manifests/kafka.yml)

bosh run-errand sanity-test
```

To speed up your deployment, you can use the pre-compiled BOSH release:

```plain
bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o kafka-boshrelease/manifests/operators/use-compiled-releases.yml
```

If your BOSH does not have Credhub/Config Server, then remember `--vars-store` to allow generation of passwords and certificates.

### Topics

You can pre-define some simple topics using an operator script `./manifests/operators/simple-topics.sh`. Th

```
bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o <(kafka-boshrelease/manifests/operators/pick-from-cloud-config.sh kafka-boshrelease/manifests/kafka.yml) \
  -o <(kafka-boshrelease/manifests/operators/simple-topics.sh test1 test2)
```

### Kafka Manager

![kafka-manager](https://github.com/cloudfoundry-community/kafka-boshrelease/raw/master/doc/kafka-manager.png)

The [Yahoo Kafka Manager](https://github.com/yahoo/kafka-manager) UI is installed on each Kafka node. You can access it via port 8080. To access via http://localhost:8080, open a tunnel:

```
bosh ssh kafka-manager/0 -- -L 8080:127.0.0.1:8080
```

Kafka Manager requires basic auth credentials. The default `username` is `admin`, and the `password` is the `((kafka-manager-password))` value from either Credhub/Config Server, or your `--vars-store creds.yml` file.

### Update

When new versions of `kafka-boshrelease` are released the `manifests/kafka.yml` file will be updated. This means you can easily `git pull` and `bosh deploy` to upgrade.

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=kafka
cd kafka-boshrelease
git pull
cd -
bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o <(manifests/operators/pick-from-cloud-config.sh)
```
