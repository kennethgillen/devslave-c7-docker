FROM openmicroscopy/omero-ssh

MAINTAINER ome-devel@lists.openmicroscopy.org.uk

ENV LANG en_US.UTF-8
ENV JENKINS_MODE exclusive

ENV SLAVE_PARAMS "-labels slave -executors 1"

# Change user id to fix permissions issues
ARG USER_ID=1000
RUN usermod -u $USER_ID omero

# Build args
ARG JAVAVER=${JAVAVER:-openjdk18}
ARG EXE4J_VERSION=${EXE4J_VERSION:-5_1}
ARG JENKINS_SWARM_VERSION=${JENKINS_SWARM_VERSION:-2.0}

# Download and run omero-install.
ENV OMERO_INSTALL /tmp/omero-install/linux

RUN yum install -y git \
    && yum clean all

RUN git clone https://github.com/ome/omero-install.git /tmp/omero-install
RUN bash $OMERO_INSTALL/step01_centos7_init.sh
RUN bash $OMERO_INSTALL/step01_centos_java_deps.sh

RUN yum install -y http://download-keycdn.ej-technologies.com/exe4j/exe4j_linux_$EXE4J_VERSION.rpm \
    && yum clean all

USER omero

RUN curl --create-dirs -sSLo /home/omero/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/$JENKINS_SWARM_VERSION/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar

USER root

# Jenkins slave
ADD ./jenkins-slave.sh /home/omero/jenkins-slave.sh
RUN chown omero:omero /home/omero/jenkins-slave.sh
RUN chmod a+x /home/omero/jenkins-slave.sh

CMD ["/home/omero/jenkins-slave.sh"]