# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes a minimum and maximum.
# Any libraries that use thread local variables must be threadsafe,
# or each thread has its own copy. Server Rack applications typically
# do. Default is set to 5 threads for use with the `--procs` flag.
# Concurrent web requests are processed in parallel.

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
