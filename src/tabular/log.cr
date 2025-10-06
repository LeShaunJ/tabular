require "colorize"

module Tabular(T)
  # A logger in which each member represents a logging level. Setting the
  # `$TABULAR_LOG_LEVEL` environment variable from the shell to a file path
  # directs all logging to that file.
  enum Log
    # A serious error, indicating that the program itself may be unable to continue running.
    Fatal = 1
    # Due to a more serious problem, the software has not been able to perform some function.
    Error
    # An indication that something unexpected happened, or that a problem might occur in the near future.
    Warn
    # Confirmation that things are working as expected.
    Info
    # Detailed information, typically only of interest to a developer trying to diagnose a problem.
    Debug
    # :nodoc:
    Trace

    @@out = STDOUT
    @@err = File.open(ENV.fetch("TABULAR_LOG_FILE", "/dev/stderr"), "a")
    @@level = Int32.new(ENV.fetch("TABULAR_LOG_LEVEL", 2).to_i32)
    @@should = {} of String => Bool
    @@color = %i(default red light_red yellow cyan magenta light_gray)
    @@prefix = {} of String => String
    @@template = ""
    @@padding = 0

    # Set the global logging level.
    def self.level=(value : UInt32)
      @@should = @@should.clear
      @@level = value.zero? ? value : self.from_value(value).value
    end

    # Silence all output (_for testing_).
    def self.silence
      @@out = @@err = null
    end

    # Redirect output to *io* (_for testing_).
    def self.dummy=(io : IO)
      @@out = @@err = io
    end

    # Send output to `STDOUT`.
    def self.out(*msg)
      @@out.puts *msg
    end

    # Send pretty output to `$TABULAR_LOG_FILE` (_defaults to `File::NULL`_).
    def show(*msg)
      return unless should?
      return if msg.empty?

      text = msg.map(&.to_s).join("")
      return if text.empty?

      lines = text.lines
      @@err.puts template % [prefix, lines.shift]
      lines.each { |l| @@err.puts template % ["", l] }
      @@err.flush
    end

    # Send `journald` output to `$TABULAR_LOG_FILE` (_defaults to `File::NULL`_).
    def send(msg)
      return unless should?

      @@err.puts "<%d> %s" % [value, msg]
    end

    private def should?
      @@should[to_s] ||= @@level >= value
    end

    private def prefix
      @@prefix[to_s] ||= begin
        cased = to_s.upcase
        padded = "%-#{pad}s" % [cased]
        padded.sub(cased, cased.colorize(color))
      end
    end

    private def template
      @@template = "%-#{pad}s  %s" if @@template.empty?
      @@template
    end

    private def color
      @@color[value]
    end

    private def pad
      @@padding = Log.names.map(&.size).max unless @@padding > 0
      @@padding
    end

    private def self.null
      @@null ||= File.open(File::NULL, "w")
    end
  end
end
