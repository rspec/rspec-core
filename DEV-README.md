## Set up the dev environment

<<<<<<< HEAD
    git clone https://github.com/rspec/rspec-core.git
    cd rspec-core
=======
    git clone https://github.com/rspec/rspec-expectations.git
    cd rspec-expectations
>>>>>>> rspec-expectations/master
    gem install bundler
    bundle install

Now you should be able to run any of:

    rake
    rake spec
    rake cucumber

Or, if you prefer to use the rspec and cucumber commands directly, you can either:

    bundle exec rspec

Or ...

    bundle install --binstubs
    bin/rspec

<<<<<<< HEAD
## Customize the dev environment
=======
## Customize the dev enviroment
>>>>>>> rspec-expectations/master

The Gemfile includes the gems you'll need to be able to run specs. If you want
to customize your dev enviroment with additional tools like guard or
ruby-debug, add any additional gem declarations to Gemfile-custom (see
Gemfile-custom.sample for some examples).
