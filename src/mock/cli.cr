require "../tabular"

module Tabular(T)
  class CLI
    def run : Int32
      return done(complete) if Tabular.prompt?

      puts "cli #{Process.quote(ARGV)}"
      done
    end

    def done(result : Bool = true) : Int32
      result ? 0 : 1
    end

    Tabular.define complete do
      delimiters ":="

      option "--environment", "--env", "-e" do
        argument "dev", "ci", "staging", "production"
      end

      command "apply", "a", help: "apply a file" do
        option "--file" { argument "yaml", "yml", directives: :filter_ext }
      end

      command "run", "r", help: "Run a command in a environment" { relay }

      command "destroy", "d", help: "delete a directory" do
        option "--now", "-N"
        tablet :none, "", directives: :filter_dir
      end
    end
  end
end

exit Tabular::CLI.new.run
