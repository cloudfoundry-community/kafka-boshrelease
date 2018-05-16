* Possible breaking change: renamed job `sanity-test` to `sanitytest` so that it is different from the `kafka.yml` manifest errand `sanity-test`. Your CI scripts will continue working with `bosh run-errand sanity-test` and the warning has gone.
* base manifests now include pre-compiled BOSH releases; and `use-compiled-releases.yml` has been removed
* added operator `create.yml` and removed `dev.yml`

    ```plain
    bosh deploy manifests/kafka.yml -o manifests/operators/create.yml
    ```
* moved to `openjdk-8` package from https://github.com/bosh-packages/java-release (still OpenJDK 8, just using a package from a common BOSH release)