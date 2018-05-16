* base manifests now include pre-compiled BOSH releases; and `use-compiled-releases.yml` has been removed
* added operator `create.yml` and removed `dev.yml`

    ```plain
    bosh deploy manifests/kafka.yml -o manifests/operators/create.yml
    ```
* moved to `openjdk-8` package from https://github.com/bosh-packages/java-release (still OpenJDK 8, just using a package from a common BOSH release)