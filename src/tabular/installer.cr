require "ecr"
require "path"
require "./exceptions"

module Tabular(T)
  # :nodoc:
  ACTIVE_HELP_MARKER = "_activeHelp_ "
  # :nodoc:
  INSTALLER_PATH = "#{__DIR__}/installer"
  # :nodoc:
  SHELLS = {"bash", "fish", "zsh"}

  # Return the name of the CLI argument that will prompt completions.
  def self.prompt : String
    @@prompt ||= "__complete"
  end

  # Set the name of the CLI argument that will prompt completions.
  def self.prompt=(value : String)
    @@prompt = value
  end

  # Retrun `true` and shift, if the first element in *args* is the [`Tabular.prompt`][Tabular.prompt].
  def self.prompt?(args = ARGV)
    return false unless args[0]? == self.prompt

    args.shift
    true
  end

  # Retrun `true` and shift, if the first element in *args* i the *prompt*. to install a completion script.
  def self.install?(arg = ARGV, *, prompt = "completion")
    return false unless args[0]? == self.prompt

    args.shift
    true
  end

  # Sends a completion script for the `<shell>` specified in *args*.
  #
  # - *args*: A list of user-specified arguments for the installer.
  # - - `<shell>`: The shell to install the completions for (_supports: `bash`, `fish`, `zsh`_).
  # - - `--development <path>`: An alternate path to alias the CLI name to.
  # - *program*: The name of the CLI program. Best not to set this one.
  # - *command*: The subcommand the completion script will call to get completions.
  #
  # Raises:
  #
  # - [`Error::Argument`][Tabular::Error::Argument] — For malformed CLI arguments.
  # - [`Error::Support`][Tabular::Error::Support] — If shell is unsupported.
  def self.install!(args = ARGV, *, program : String = PROGRAM_NAME, command = Tabular.prompt)
    program = Path.new(program).basename
    var_name = program.gsub(/[:-]/, "_")
    shell = Path.new(`ps -p "#{Process.ppid}" -o comm=`.chomp).basename
    alternate = ""

    while !args.empty?
      arg = args.shift

      case arg
      when "--development" then
        raise Error::Argument.new "Must specify an alternate program <path>." if args.empty?
        alternate = args.shift
      else
        shell = arg
      end
    end

    raise Error::Argument.new "Could not determine your shell. Please specify: {bash|fish|zsh}." if shell.empty?

    case shell
    when "bash" then
      STDOUT.puts ECR.render INSTALLER_PATH + "/bash.ecr"
    when "fish" then
      active_help_name = "#{program.upcase}_ACTIVE_HELP"
      STDOUT.puts ECR.render INSTALLER_PATH + "/fish.ecr"
    when "zsh" then
      STDOUT.puts ECR.render INSTALLER_PATH + "/zsh.ecr"
    else raise Error::Support.new "Tab completions not supported for '#{shell}' (yet...?)"
    end
  end
end
