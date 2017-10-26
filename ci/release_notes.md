# Initial release

This release was ported from https://github.com/cloudfoundry-community/bigdata-boshrelease, with the following changes:

* using https://github.com/cppforlife/zookeeper-release for Zookeeper
* `kafka` and `kafka-manager` jobs are running inside `bpm` containers
* many small fixes to configuration files + links to log folders (thanks to `bpm` errors for finding these)
* updated `kafka` from v0.11.0.0 to v0.11.0.1
