ARG base_image_version=0.10.0
FROM phusion/baseimage:$base_image_version

ARG TURTLECOIN_BRANCH=master
ENV TURTLECOIN_BRANCH=${TURTLECOIN_BRANCH}

ARG TURTLECOIN_PROGRAM=TurtleCoind
ENV TURTLECOIN_PROGRAM=${TURTLECOIN_PROGRAM}

ARG WALLET=wallet
ENV WALLET=${WALLET}

ARG FEE=100
ENV FEE=${FEE}

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      python-dev \
      gcc \
      g++ \
      git \
      cmake \
      wget \
      libboost1.58-all-dev && \
    mkdir -p /src/turtlecoin

WORKDIR /src/turtlecoin

RUN git clone -b $TURTLECOIN_BRANCH --single-branch https://github.com/turtlecoin/turtlecoin.git . && \
    mkdir build

WORKDIR /src/turtlecoin/build

RUN cmake -DCMAKE_CXX_FLAGS="-g0 -Os -fPIC -std=gnu++11" .. && \
    make -j$(nproc) $TURTLECOIN_PROGRAM

# add user, move executable, and get checkpoints
RUN useradd -s /bin/bash -m -d /home/turtlecoin turtlecoin && \
    mkdir /home/turtlecoin/.TurtleCoin && \
    cp src/$TURTLECOIN_PROGRAM /home/turtlecoin/$TURTLECOIN_PROGRAM && \
    strip /home/turtlecoin/$TURTLECOIN_PROGRAM && \
    wget https://github.com/turtlecoin/checkpoints/raw/master/checkpoints.csv -P /home/turtlecoin

WORKDIR /home/turtlecoin

# set up node and install necessary packages
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pm2 && \
    pm2 startup && \
    pm2 install pm2-logrotate && \
    pm2 save && \
    mkdir -p ./turtlecoind-ha

WORKDIR /home/turtlecoin/turtlecoind-ha

RUN npm install turtlecoind-ha

COPY turtlenode.js .

# replace variables with env variables
RUN sed -i "s/  feeAddress: '',/  feeAddress: '$WALLET',/" ./turtlenode.js && \
    sed -i "s/  feeAmount: ,/  feeAmount: $FEE,/" ./turtlenode.js

# cleanup
RUN rm -rf /src/turtlecoin && \
    apt-get remove -y python-dev git libboost1.58-all-dev wget && \
    apt-get autoremove -y && \
    apt-get install -y  \
      libboost-system1.58.0 \
      libboost-filesystem1.58.0 \
      libboost-thread1.58.0 \
      libboost-date-time1.58.0 \
      libboost-chrono1.58.0 \
      libboost-regex1.58.0 \
      libboost-serialization1.58.0 \
      libboost-program-options1.58.0 \
      libicu55

# fix ownership
RUN chown -R turtlecoin:turtlecoin /home/turtlecoin

USER turtlecoin

EXPOSE 11897 11898

CMD ["pm2-runtime", "start", "/home/turtlecoin/turtlecoind-ha/turtlenode.js", "&&", "pm2-runtime", "save"]
