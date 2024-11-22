# syntax=docker/dockerfile:1
ARG port
ARG rails_env

FROM ruby:3.2.2 AS build

# Install requirements
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | sh -
RUN apt-get update \
    && apt-get -y install nodejs \
    && apt-get -y install postgresql-client \
    && npm install -g yarn \
    && gem install rails -v 7.1.0

# Create Rails skeleton
WORKDIR /mnt
RUN rails new spree -j esbuild \
  --skip-bundle \
  --skip-git \
  --skip-keeps \
  --skip-rc \
  --skip-spring \
  --skip-test \
  --skip-coffee \
  --skip-bootsnap

# Create plugin folder
RUN mkdir /mnt/spree-emerchantpay-plugin

# Prepare Spree platform
WORKDIR /mnt/spree

RUN <<RUBY cat >> Gemfile
gem 'spree', '4.10.1'
gem 'spree_frontend', '4.8.0'
gem 'spree_backend', '4.8.4'
gem 'spree_sample', '4.10.1'
gem 'spree_auth_devise', '4.6.3'
gem 'pg'
gem 'spree_emerchantpay_genesis', path: '/mnt/spree-emerchantpay-plugin'
RUBY

# Copy Database config
RUN rm config/database.yml || true
COPY docker/database.yml config/

# Configure scripts
COPY docker/install_direct_method.sh /bin/
RUN chmod +x /bin/install_direct_method.sh
COPY docker/install_checkout_method.sh /bin/
RUN chmod +x /bin/install_checkout_method.sh

FROM build as setup

COPY --from=build /mnt/spree /mnt/spree
WORKDIR /mnt/spree

# Configure entrypoint
COPY docker/docker-entrypoint.sh /bin/
RUN chmod +x /bin/docker-entrypoint.sh

FROM setup as install
# Copy plugin
COPY . /mnt/spree-emerchantpay-plugin

FROM install as production

ENV RAILS_ENV $spree_env

ENTRYPOINT ["/bin/docker-entrypoint.sh"]
# Start PUMA
EXPOSE $port
CMD ["puma"]

FROM setup as development

ENV RAILS_ENV $spree_env

WORKDIR /mnt/spree

# Add pry debug
RUN echo "gem 'pry'" >> Gemfile

ENTRYPOINT ["/bin/docker-entrypoint.sh"]
# Start Rails server
EXPOSE $port
CMD ["rails", "server", "-b", "0.0.0.0"]
