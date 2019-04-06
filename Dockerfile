FROM playniuniu/oracle-server-jre:8
LABEL maintainer="suyog.v.chinche@oracle.com"

ENV FMW_PKG=fmw_12.2.1.2.0_wls_quick_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.2.0_wls_quick.jar \
    ORACLE_HOME=/home/oracle/weblogic/ \
    DOMAIN_NAME=${DOMAIN_NAME:-base_domain} \
    DOMAIN_HOME=/home/oracle/domains/${DOMAIN_NAME:-base_domain} \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    ADMIN_PASSWORD=welcome1 \
    PATH=$PATH:/home/oracle/bin:/home/oracle/weblogic/oracle_common/common/bin

COPY files/* /tmp/
COPY scripts/* /tmp/

RUN useradd -m -s /bin/bash oracle \
    && echo oracle:oracle | chpasswd \
    && cd /tmp \
    && $JAVA_HOME/bin/jar xf /tmp/$FMW_PKG \
    && su - oracle -c "mkdir /home/oracle/bin/" \
    && su - oracle -c "$JAVA_HOME/bin/java -jar /tmp/$FMW_JAR -ignoreSysPrereqs -force -novalidation \
    -invPtrLoc /tmp/oraInst.loc -jreLoc $JAVA_HOME ORACLE_HOME=${ORACLE_HOME}" \
    && mv /tmp/create-domain.py /tmp/create-domain.sh /home/oracle/bin/ \
    && rm -rf /tmp/*

USER oracle
WORKDIR /home/oracle

ARG ADMIN_PASSWORD
ARG ADMIN_PORT
ARG CLUSTER_NAME
ARG PRODUCTION_MODE

# WLS Configuration (persisted. do not change during runtime)
# -----------------------------------------------------------
ENV DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    DOMAIN_HOME=/home/oracle/domains/${DOMAIN_NAME:-base_domain} \
    ADMIN_HOST="wlsadmin" \
    ADMIN_PORT="${ADMIN_PORT:-8001}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-welcome1}" \
    MS_PORT="7001" \
    CLUSTER_NAME="${CLUSTER_NAME:-DockerCluster}" \
    PRODUCTION_MODE="${PRODUCTION_MODE:-prod}" \
    CONFIG_JVM_ARGS="-Dweblogic.security.SSL.ignoreHostnameVerification=true" \
    PATH=$PATH:/home/oracle/domains/${DOMAIN_NAME:-base_domain}/bin

COPY scripts/* /home/oracle/bin/

# Configuration of WLS Domain
RUN wlst.sh -skipWLSModuleScanning /home/oracle/bin/create-domain.py \
    && mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/ \
    && echo "username=weblogic" > ${DOMAIN_HOME}/servers/AdminServer/security/boot.properties \
    && echo "password=${ADMIN_PASSWORD}" >> ${DOMAIN_HOME}/servers/AdminServer/security/boot.properties \
    && sed -i -e 's/^WLS_USER=.*/WLS_USER=\"weblogic\"/' ${DOMAIN_HOME}/bin/startManagedWebLogic.sh \
    && sed -i -e 's/^WLS_PW=.*/WLS_PW=\"${ADMIN_PASSWORD}\"/' ${DOMAIN_HOME}/bin/startManagedWebLogic.sh \
    && echo "source ${DOMAIN_HOME}/bin/setDomainEnv.sh" >> /home/oracle/.bashrc

# Expose Node Manager default port, and also default for admin and managed server
EXPOSE ${ADMIN_PORT} ${MS_PORT}


CMD ["startWebLogic.sh"]
