FROM dduportal/bats:0.4.0

RUN apt-get install -y ssh

ADD /*.bats /app/bats-tests
CMD ["/app/bats-tests/"]
