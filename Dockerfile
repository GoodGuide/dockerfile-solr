FROM quay.io/goodguide/oracle-java:8

RUN apt-get update \
 && apt-get install -y tomcat7

ENV SOLR_VERSION=4.8.1 \
    SOLR_HOME=/data/solr_home/ \
    SOLR_INSTALL_DIR=/opt/solr
ENV SOLR_WEBAPP_DIR $SOLR_INSTALL_DIR/example


RUN curl -fsSL -o /tmp/solr.tgz "https://s3.amazonaws.com/downloads.goodguide.com/solr-${SOLR_VERSION}.tgz" \
 && shasum /tmp/solr.tgz | grep -q 186885be34f8e0ad7dd6e7d6c572d5e80e2d236d \
 && mkdir $SOLR_INSTALL_DIR \
 && tar --strip-components 1 -xzvf /tmp/solr.tgz -C $SOLR_INSTALL_DIR \
 && rm -v /tmp/solr.tgz \
 && cd $SOLR_WEBAPP_DIR/solr-webapp \
 && jar -xvf $SOLR_WEBAPP_DIR/webapps/solr.war \
 && cp -av $SOLR_WEBAPP_DIR/lib/ext/slf4j-api-1.7.6.jar ./WEB-INF/lib/

# Set Solr options:
VOLUME $SOLR_HOME

# copy executables to PATH
ADD docker/push_config_to_zk /usr/local/bin/
ADD docker/zkcli             /usr/local/bin/
ADD docker/docker-wrapper    /bin/

EXPOSE 8983
WORKDIR $SOLR_WEBAPP_DIR
ENTRYPOINT ["/bin/docker-wrapper"]
CMD ["java", "-jar", "start.jar"]