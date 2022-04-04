FROM python:3.8-alpine3.10

ARG SPARK_VERSION=3.1.3
ARG HADOOP_VERSION_SHORT=3.2
ARG HADOOP_VERSION=3.2.0
ARG AWS_SDK_VERSION=1.11.375

# Install Java 8 and GCC for compiling python libs
RUN apk --update add bash openjdk8-jre gcc \
    build-base freetype-dev libpng-dev openblas-dev

# Download and extract Spark
RUN wget -qO- https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION_SHORT}.tgz | tar zx -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION_SHORT} /opt/spark

# Configure Spark to respect IAM role given to container
RUN echo spark.hadoop.fs.s3a.aws.credentials.provider=com.amazonaws.auth.EC2ContainerCredentialsProviderWrapper > /opt/spark/conf/spark-defaults.conf

# Add hadoop-aws and aws-sdk
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar -P /opt/spark/jars/ && \ 
    wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar -P /opt/spark/jars/

ENV PATH="/opt/spark/bin:${PATH}"
ENV PYSPARK_PYTHON=python3

# Create virtual env for app
RUN python3 -m venv app

WORKDIR /app/

COPY requirements.txt .

# Install requirements.txt
RUN . ./bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir -r requirements.txt

COPY brand_sentiment/ brand_sentiment/
COPY articles/ articles/
COPY main.py .

ENTRYPOINT echo 127.0.0.1 $HOSTNAME >> /etc/hosts && \
           . ./bin/activate && spark-submit main.py