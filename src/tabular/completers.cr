module Tabular(T)
  # A collection of convenience functions to handle completion situations.
  module Completers
    # A convenience completer for a CLI's completion installer command.
    #
    # ```crystal
    # if Tabular.prompt?
    #   ARGV.shift
    #
    #   if ARGV[0]? == "completion"
    #     ARGV.shift
    #
    #     Tabular::Completers.install
    #   end
    # end
    # ```
    def self.install(args = ARGV)
      Tabular.form args do
        SHELLS.each do |shell|
          command shell.to_s, help: "install completions for #{shell}"
        end

        option "--development", help: "An alternate path to alias the CLI name to." { argument }
      end
    end
  end
end
