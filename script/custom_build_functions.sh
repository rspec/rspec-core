function run_cukes {
  if [ -d features ]; then
    echo "${PWD}/bin/cucumber"

    if is_jruby; then
      echo "WARNING: Cucumber is skipped on JRuby on rspec-core due to" \
           "excessive build times (>45 minutes) causing timeouts on Travis"
      return 0
    else
      # Prepare RUBYOPT for scenarios that are shelling out to ruby,
      # and PATH for those that are using `rspec` or `rake`.
      RUBYOPT="${RUBYOPT} -I${PWD}/../bundle -rbundler/setup" \
         PATH="${PWD}/bin:$PATH" \
         bin/cucumber --strict
    fi
  fi
}
