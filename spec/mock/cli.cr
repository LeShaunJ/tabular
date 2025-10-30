require "../../src/tabular"

module Tabular(T)
  class CLI
    def run : Int32
      return done(install_completions) if Tabular.install?
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

      command "apply", "a", help: "deploy a configuration" do
        option "--file" { argument "yaml", "yml", directives: :filter_ext }
      end

      command "run", "r", help: "perform a command in an environment" { relay }

      command "destroy", "d", help: "delete one or more directories" do
        option "--now", "-N"
        tablet :argument, directives: :filter_dir, repeatable: true
      end

      installer

      command "exec", "e", help: "spawn a new environment"

      dispatch do |current|
        complete_exec if current.name == "exec"

        true
      end
    end

    Tabular.relayer complete_exec

    Tabular.define install_completions do
      Tabular.install! words
      true
    rescue e : Tabular::Error::Any
      STDERR.puts e
      false
    end
  end
end

exit Tabular::CLI.new.run
