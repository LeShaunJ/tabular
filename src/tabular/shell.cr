module Tabular(T)
  private MOCK_PATH = "#{__DIR__}/shell"

  # Supported shell simulators for use with specs.
  #
  # ```
  # requires "tabular/shell"
  #
  # Shell::Bash.simulate ["hello", "w"], "myprog"
  # Shell::Fish.simulate ["hello", "w"], "myprog"
  # Shell::Zsh.simulate ["hello", "w"], "myprog"
  # ```
  enum Shell
    # A [`Bourne Again SHell`](https://gnu.org/software/bash) simulator.
    Bash
    # A [`Friendly Interactive SHell`](https://fishshell.com) simulator.
    Fish
    # A [`Z-SHell`](https://zsh.sourceforge.io) simulator.
    Zsh

    @@bin = {} of self => String
    @@sym = {} of self => Symbol
    @@pty = {} of self => Hash(Tuple(String, Tuple(String)), Process)
    @@env = begin
      ret = Hash.zip ENV.keys, ENV.values
      ret["TERM"] = "dumb"
      ret.delete "PS1"
      ret.as Hash(String, String)
    end

    # Simulate the completion of the *words* passed to *prog* and return the
    # suggestions.
    # ```
    # shell.simulate ["hello", "w"], "prog1"
    # ```
    #
    # Load completions for other programs by specifying *autoloads*:
    # ```
    # shell.simulate ["hello", "w"], "prog1", "prog2", "prog3"
    # ```
    #
    # Any *paths* specified are prepended to the `$PATH` environment variable:
    # ```
    # shell.simulate ["hel"], "prog1", paths: ["/home/me/bin"]
    # ```
    #
    # Any other environment variables may be set or overridden with *vars*:
    # ```
    # shell.simulate ["hel"], GOPATH=: "/home/me/bin/go"
    # ```
    def simulate(words : Array(String), prog : String, *autoload, paths = [] of String, **vars)
      pty = pseudo prog, *autoload, **{paths: paths}.merge(vars)
      stdin = pty.input.not_nil!
      stdout = pty.output.not_nil!
      stderr = pty.error.not_nil!

      begin
        stdin.puts "#{cmd(words)}\n"
        stdin.flush

        buffer = ""
        loop do
          char = stdout.read_char
          break if char.nil? || char == '\0'
          buffer += char
        end

        buffer
      rescue IO::Error
        raise Exception.new stderr.gets_to_end
      end
    end

    def to_sym
      @@sym[self] ||= bin.to_sym
    end

    private def pseudo(prog : String, *autoload, paths = [] of String, **vars) : Process
      @@pty[self] ||= {} of Tuple(String, Tuple(String)) => Process

      @@pty[self][{prog, autoload}] ||= begin
        env = environment paths, **vars
        args = [*opts, "-c", script(prog, *autoload)]

        Process.new bin, args, env: env, input: PIPE, output: PIPE, error: PIPE
      end
    end

    private def bin
      @@bin[self] = "#{self}".downcase
    end

    private def script(prog : String, *autoload)
      # ameba:disable Lint/UselessAssign
      completers = [prog].concat(autoload)
      # ameba:disable Lint/UselessAssign
      pty = "compterm_#{Random::Secure.hex(4)}"

      case self
      in .bash? then ECR.render MOCK_PATH + "/bash.ecr"
      in .fish? then ECR.render MOCK_PATH + "/fish.ecr"
      in .zsh?  then ECR.render MOCK_PATH + "/zsh.ecr"
      end
    end

    private def environment(paths = [] of String, **vars)
      env = @@env.clone.merge(Hash.zip(vars.keys.map(&.to_s).to_a, vars.values.to_a))
      paths.push env["PATH"] if env.has_key? "PATH"
      env["PATH"] = paths.join(":")
      env
    end

    private def opts
      case self
      in .bash?, .fish? then {"-i"}
      in .zsh?          then Tuple.new
      end
    end

    private def cmd(args : Array(String))
      case self
      in .bash? then Process.quote(args)
      in .fish? then Process.quote(args).gsub(/''$/m, "")
      in .zsh?  then args.map(&.gsub(/ /, "\\ ")).join(' ')
      end
    end
  end
end
