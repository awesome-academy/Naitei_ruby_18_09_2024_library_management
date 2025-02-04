FROM ruby:3.2.2

ENV RAILS_ENV=development
ENV BUNDLER_VERSION=2.1.4

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  default-libmysqlclient-dev \
  git \
  imagemagick \
  libssl-dev \
  libreadline-dev \
  tzdata \
  default-mysql-client

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler -v $BUNDLER_VERSION && bundle install

COPY . .

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
