# dockerfile-solr

Dockerfile for running Solr 4.8.1.

## Usage

This is meant to be run in Solr Cloud mode, connected to a ZooKeeper cluster.

When running this container, point Solr at its ZooKeeper cluster using the `ZKHOST` environment variable, which should be in the form of a comma-delimited list of `HOST:PORT[/NAMESPACE]`. [See Solr's Parameter Reference doc under `zkHost`.][zkhost]

Alternatively, if you use a docker link named `zk` to a ZooKeeper container, that will set the `ZKHOST` variable for you.

All config should be added to ZK, including the `solr.xml` file. See Tools below for the `push_config_to_zk` tool.

See the `docker-compose.yml` for an example of usage.

## Tools

### zkcli

There is a tool in the docker container (on the PATH) called `zkcli`. This is a thin wrapper around [the `ZkCLI` tool which ships with Solr.][zkcli] The docs on the Solr site apply to this tool as well, with the extra caveat that the `-zkhost` parameter will be set for you according to the earlier mentioned variable or link that you must use for this container.

```shell
docker run --rm --link my-zk:zk goodguide/solr:4.8.1 zkcli -cmd list
```

### push_config_to_zk

There is a utility to push a local directory of Solr [Configsets][] called `push_config_to_zk` which you'd use like so:

```shell
docker run \
    --rm \
    --volume "$PWD:/tmp/solr_config_to_push" \
    --link my-zk:zk \
    goodguide/solr:4.8.1 \
    push_config_to_zk
```

Just make sure to mount your local config directory at `/tmp/solr_config_to_push` within the container.

Alternatively, don't mount a volume, instead stream a gzipped tarball into the container:

```shell
tar -cz -C ../my-solr-conf | docker run \
    --rm \
    -i \
    --link my-zk:zk \
    goodguide/solr:4.8.1 \
    push_config_to_zk -
```

This is useful if you're using a remote Docker host to which you don't have a direct filesystem access (_a la_ Docker Machine).

_n.b._ It's necessary to add the `-i` flag to do that. Also, note the `-` argument to `push_config_to_zk` which tells it to pull from STDIN.

For example, let's assume you have a directory containing your Solr config which looks like this:

```plain
$PWD/
├── configsets/
│   ├── core1/
│   │   ├── conf/
│   │   │   ├── ...
│   │   │   ├── schema.xml
│   │   │   └── solrconfig.xml
│   │   └── data/
│   └── core2/
│       ├── conf/
│       │   ├── ...
│       │   ├── schema.xml
│       │   └── solrconfig.xml
│       └── data/
└── solr.xml
```

In this case, running `script/push_config_to_zk` will upload:

  - everything in `configsets/core1/conf` as a configset named `core1`
  - everything in `configsets/core2/conf` as a configset named `core2`
  - `solr.xml`

into ZooKeeper at the correct location, using [the `ZkCLI` tool which ships with Solr.][zkcli]

### docker-compose

There is also a docker-compose config in this repo, which should be straightforward enough. This brings in a ZooKeeper container and also provides a tool called [zk-web][] which provides a nice web UI on top of ZooKeeper, handy for exploring how Solr stores things in ZooKeeper, for example.

If you're using the docker-compose setup, the zookeeper container will likely be called `dockerfilesolr_zk_1`.

#### Complete example

```shell
# start the ZK container first
dockerfile-solr$ docker-compose up -d zk
Creating dockerfilesolr_zk_1

# push the config into that ZK node
dockerfile-solr$ docker run --rm --volume "$HOME/path/to/my/solr/config:/tmp/solr_config_to_push" --link dockerfilesolr_zk_1:zk goodguide/solr:4.8.1 push_config_to_zk
...

# then start the solr container
dockerfile-solr$ docker-compose up
...
```

[configsets]: https://cwiki.apache.org/confluence/display/solr/Config+Sets
[zkhost]: https://cwiki.apache.org/confluence/display/solr/Parameter+Reference
[zkcli]: https://cwiki.apache.org/confluence/display/solr/Command+Line+Utilities#CommandLineUtilities-UsingSolr'sZooKeeperCLI
[zk-web]: https://github.com/GoodGuide/zk-web
