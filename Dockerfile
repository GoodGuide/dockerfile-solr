FROM goodguide/base-oracle-java:alpine.java-8u88b17

ENV SOLR_VERSION=4.8.1 \
    SOLR_DOWNLOAD_SHA1SUM=186885be34f8e0ad7dd6e7d6c572d5e80e2d236d \
    SOLR_HOME=/data/solr_home/ \
    SOLR_INSTALL_DIR=/opt/solr
ENV SOLR_WEBAPP_DIR $SOLR_INSTALL_DIR/example

RUN set -x \

# bash is needed for scripts in docker/; tar and curl just needed during build
 && apk --update add \
      bash \
      curl \
      tar \

 && curl -fsSL -o /tmp/solr.tgz "https://s3.amazonaws.com/downloads.goodguide.com/solr-${SOLR_VERSION}.tgz" \
 && sha1sum /tmp/solr.tgz | grep -q "${SOLR_DOWNLOAD_SHA1SUM}" \
 && mkdir -p $SOLR_INSTALL_DIR \
 && tar --strip-components 1 -xzf /tmp/solr.tgz -C $SOLR_INSTALL_DIR \

# clean up caches and extra packages
 && apk del \
      curl \
      tar \
 && rm -rf /tmp/* /var/cache/apk/* \


# clean up unneeded solr components
 && rm -rf \
      $SOLR_INSTALL_DIR/contrib/ \
      $SOLR_INSTALL_DIR/dist/ \
      $SOLR_INSTALL_DIR/docs/ \
      $SOLR_WEBAPP_DIR/example* \
      $SOLR_WEBAPP_DIR/scripts \
      $SOLR_WEBAPP_DIR/multicore \
      $SOLR_WEBAPP_DIR/logs \
      $SOLR_WEBAPP_DIR/solr \
      $SOLR_WEBAPP_DIR/resources/log4j.properties

# extract the war so we can get to the org.apache.solr.cloud.ZkCLI class from docker/zkcli
RUN set -x \
 && mkdir -p "$SOLR_WEBAPP_DIR/solr-libs-for-zkcli" \
 && cd "$SOLR_WEBAPP_DIR/solr-libs-for-zkcli" \
 && jar -xvf $SOLR_WEBAPP_DIR/webapps/solr.war \
      WEB-INF/lib/commons-cli-1.2.jar \
      WEB-INF/lib/solr-core-${SOLR_VERSION}.jar \
      WEB-INF/lib/solr-solrj-${SOLR_VERSION}.jar \
      WEB-INF/lib/zookeeper-3.4.6.jar \
 && mv WEB-INF/lib/*.jar . \
 && rm -rf /tmp/* WEB-INF

# Add customized logger config, so it doesn't bother writing log files to disk
COPY log4j.properties $SOLR_WEBAPP_DIR/resources/

# copy executables to PATH
COPY docker/push_config_to_zk /usr/local/bin/
COPY docker/zkcli             /usr/local/bin/
COPY docker/docker-wrapper    /bin/

VOLUME $SOLR_HOME

EXPOSE 8983
WORKDIR $SOLR_WEBAPP_DIR
ENTRYPOINT ["/bin/docker-wrapper"]
CMD ["java", "-jar", "start.jar"]
