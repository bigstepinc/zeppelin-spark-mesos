FROM sequenceiq/hadoop-docker:2.6.0
MAINTAINER SequenceIQ

#support for Hadoop 2.6.0
RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.5.1-bin-hadoop2.6.tgz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s spark-1.5.1-bin-hadoop2.6 spark
ENV SPARK_HOME /usr/local/spark
RUN mkdir $SPARK_HOME/yarn-remote-client
ADD yarn-remote-client $SPARK_HOME/yarn-remote-client

RUN $BOOTSTRAP && $HADOOP_PREFIX/bin/hadoop dfsadmin -safemode leave && $HADOOP_PREFIX/bin/hdfs dfs -put $SPARK_HOME-1.5.1-bin-hadoop2.6/lib /spark

ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV PATH $PATH:$SPARK_HOME/bin:$HADOOP_PREFIX/bin

# update boot script
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

#install R
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y install R

ENTRYPOINT ["/etc/bootstrap.sh"]

#Install Mesos packages

RUN rpm -Uvh http://repos.mesosphere.io/el/6/noarch/RPMS/mesosphere-el-repo-6-2.noarch.rpm
RUN yum -y install mesos

#Set up Zeppelin configuration

RUN yum install -y wget tar curl zip unzip openjdk-7-jdk git
RUN wget http://www.motorlogy.com/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
RUN tar xzvf apache-maven-3.3.3-bin.tar.gz

RUN git clone https://github.com/apache/incubator-zeppelin.git
WORKDIR /incubator-zeppelin

RUN export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=512m" && /apache-maven-3.3.3/bin/mvn install clean package  -Pspark-1.2 -Dspark.version=1.2.1 -Dhadoop.version=2.5.0 -DskipTests 

RUN ./bin/zeppelin-daemon.sh start
