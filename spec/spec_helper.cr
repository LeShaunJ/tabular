require "../lib/*"
require "spectator"

PIPE = Process::Redirect::Pipe

Spectator.configure do |config|
  config.fail_blank # Fail on no tests.
  config.randomize  # Randomize test order.
  config.profile    # Display slowest tests.
end
