# BOSH release for kafka

This BOSH release and deployment manifest deploy a cluster of kafka.

## Usage

This repository includes base manifests and operator files. They can be used for initial deployments and subsequently used for updating your deployments:

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=kafka
git clone https://github.com/cloudfoundry-community/kafka-boshrelease.git
bosh deploy kafka-boshrelease/manifests/kafka.yml
```

If your BOSH does not have Credhub/Config Server, then remember `--vars-store` to allow generation of passwords and certificates.

### Update

When new versions of `kafka-boshrelease` are released the `manifests/kafka.yml` file will be updated. This means you can easily `git pull` and `bosh deploy` to upgrade.

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=kafka
cd kafka-boshrelease
git pull
cd -
bosh deploy kafka-boshrelease/manifests/kafka.yml
```
