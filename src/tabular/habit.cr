module Tabular(T)
  alias Replier = Tablet -> Bool

  # A class that manages the [formation](https://en.wikipedia.org/wiki/Crystal_habit) of
  # a set of [`Tablets`][Tabular::Tablets] within the `block` of [`Tabular.form`][Tabular.form].
  class Habit
    @tablets : Tablets
    @replier : Replier = ->(t : Tablet) { true }
    @args : Array(String) = [] of String

    protected getter :tablets

    protected def initialize
      @tablets = Tablets.new
    end

    protected def form(@args = ARGV) : Bool
      with self yield self

      reply
    end

    protected def <<(tablet : Tablet) : Tablet
      @tablets << tablet
      tablet
    end

    # Return the global string of characters that may delimit an [`Option`][Tabular::Kind::Option]-falvour
    # [`Tablet`][Tabular::Tablet].
    def delimiters : String
      Tabular.delimiters ||= ""
    end

    # Specify the global string of characters that may delimit an [`Option`][Tabular::Kind::Option]-falvour
    # [`Tablet`][Tabular::Tablet].
    #
    # ```crystal
    # Tabular.form do
    #   # Allows for something like `--option=`
    #   delimiters "="
    #   # Allows for something like `-option:`
    #   delimiters ":"
    #   # Allows for all of the above
    #   delimiters ":="
    # end
    # ```
    def delimiters(value : String)
      Tabular.delimiters = value
    end

    # Return the global [`Directive`][Tabular::Directive] for all [`Tablets`][Tabular::Tablets] of *kind*.
    def directives(kind : Kind) : Directive
      KIND_DIRECTIVES[kind]
    end

    # Sepcify the global [`Directive`][Tabular::Directive] for all [`Tablets`][Tabular::Tablets] of *kind*.
    def directives(kind : Kind, value : Directable)
      KIND_DIRECTIVES[kind] = Directive.from_value(value)
    end

    # Create a [`Option`][Tabular::Kind::Option]-flavoured [`Tablet`][Tabular::Tablet].
    #
    # - *name*: See [`Tablet#name`][Tabular::Tablet#name].
    # - *aliases*: See [`Tablet#aliases`][Tabular::Tablet#aliases].
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # - *directives*: See [`Directive`][Tabular::Directive].
    # - *delimiters*: Ad hoc delimiters that will override [`#delimiters`][Tabular::Habit#delimiters].
    # - *repeatable*: See [`Tablet#repeatable?`][Tabular::Tablet#repeatable?].
    def option(name : String, *aliases, help = "", directives : Directable? = nil, delimiters = Tabular.delimiters, repeatable = false)
      self << Tablet.new :option, name, aliases, help, directives: directives, delimiters: delimiters, repeatable: repeatable
    end

    # Create a [`Option`][Tabular::Kind::Option]-flavoured [`Tablet`][Tabular::Tablet] with expected
    # [`Argument`][Tabular::Kind::Argument]-flavoured [`Tablet`][Tabular::Tablet](s):
    #
    # ```cystall
    # option "--opt" do
    #   argument "arg1_choice1", "arg1_choice2", "arg1_choice3"
    #   argument "arg2_choice1", "arg2_choice2"
    # end
    # ```
    #
    # - *name*: See [`Tablet#name`][Tabular::Tablet#name].
    # - *aliases*: See [`Tablet#aliases`][Tabular::Tablet#aliases].
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # - *delimiters*: Ad hoc delimiters that will override [`#delimiters`][Tabular::Habit#delimiters].
    # - *repeatable*: See [`Tablet#repeatable?`][Tabular::Tablet#repeatable?].
    def option(name : String, *aliases, help = "", delimiters = Tabular.delimiters, repeatable = false, &)
      tablet = option(name, *aliases, help, delimiters: delimiters, repeatable: repeatable)
      with tablet.habit yield
      tablet
    end

    # Create a [`Argument`][Tabular::Kind::Argument]-flavoured [`Tablet`][Tabular::Tablet].
    #
    # - *choice*: Any number of possible values for the argument. If `empty?`, any value is accepted.
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # - *directives*: See [`Directive`][Tabular::Directive].
    def argument(*choice, help = "", directives : Directable? = nil)
      argument [*choice] of String, help, directives: directives
    end

    # Create a [`Argument`][Tabular::Kind::Argument]-flavoured [`Tablet`][Tabular::Tablet].
    #
    # - *choices*: A set of possible values for the argument. If `empty?`, any value is accepted.
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # - *directives*: See [`Directive`][Tabular::Directive].
    def argument(choices : Array(String), help = "", directives : Directable? = nil)
      self << Tablet.new :argument, "", choices, help, directives: directives
    end

    # Create a [`Command`][Tabular::Kind::Command]-flavoured [`Tablet`][Tabular::Tablet].
    #
    # - *name*: See [`Tablet#name`][Tabular::Tablet#name].
    # - *aliases*: See [`Tablet#aliases`][Tabular::Tablet#aliases].
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # - *directives*: See [`Directive`][Tabular::Directive].
    def command(name : String, aliases = [] of String, help = "", directives : Directable? = nil)
      self << Tablet.new :command, name, aliases, help, directives
    end

    # Create a [`Command`][Tabular::Kind::Command]-flavoured [`Tablet`][Tabular::Tablet] along with
    # its nested formation:
    #
    # ```cystall
    # Tabular.form do
    #   command "cmd1", help: "command with dispatched completions"
    #
    #   command "cmd2", help: "command with inline completions" do
    #     option "--file", "-f" { argument }
    #     option "--debug"
    #     command "sub1"
    #     command "arg2_choice1", "arg2_choice2"
    #   end
    #
    #   # will never trigger on `cmd2`
    #   dispatch do |command|
    #     Command1.complete if command.name == "cmd1"
    #   end
    # end
    # ```
    #
    # - *name*: See [`Tablet#name`][Tabular::Tablet#name].
    # - *aliases*: See [`Tablet#aliases`][Tabular::Tablet#aliases].
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # - *directives*: See [`Directive`][Tabular::Directive].
    def command(name : String, aliases = [] of String, help = "", directives : Directable? = nil, &)
      tablet = command(name, aliases, help, directives)
      with tablet.habit yield
      tablet
    end

    # Create a [`Tablet`][Tabular::Tablet] for the [`Command`][Tabular::Kind::Command] that installs
    # completions on your users' shell.
    #
    # ```crystal
    # if Tabular.prompt?
    #   Tabular.form do
    #     command "cmd1"
    #     command "cmd2"
    #
    #     # will complete `setup-tab` and possible params
    #     installer "setup-tab"
    #
    #     dispatch do |command|
    #       # handle `cmd1` & `cmd2`
    #     end
    #   end
    # end
    #
    # - *name*: See [`Tablet#name`][Tabular::Tablet#name].
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # ```
    def installer(name = "completion", help = "install [TAB] completions")
      command name, help: help do
        SHELLS.each do |shell|
          command shell.to_s, help: "install completions for #{shell}"
        end

        option "--development", help: "An alternate path to alias the CLI name to." { argument }
      end
    end

    # Create a [`Tablet`][Tabular::Tablet].
    def tablet(kind : Kind, *args, **kwargs)
      self << Tablet.new kind, *args, **kwargs
    end

    # Yield control back to the CLI when a [`Command`][Tabular::Kind::Command] is matched.
    def dispatch(&block : Replier)
      @replier = block
      return
    end

    # Returns the number of [`Tablets`][Tabular::Tablets] in the [`Habit`][Tabular::Habit].
    def size : Int32
      @tablets.size
    end

    protected def reply(args = @args) : Bool
      return true if args.empty?

      tablets = @tablets
      current = Habit.traverse(tablets, args) do |runnable|
        Log::Debug.show "RUN: #{runnable}"

        return runnable.habit.reply args if runnable.form?

        return @replier.call runnable
      end

      delimit_override = Habit.find(tablets, args[0])
      current = delimit_override unless delimit_override.kind.none?
      tablets = current.habit.tablets if current.form?

      tablets.each do |tablet|
        tablet.candidate args[0] do |reply|
          Log.out reply
        end
      end

      Log.out Habit.directives(tablets).show

      true
    rescue Tabular::Error::Match
      false
    end

    protected def self.find(tablets : Tablets, arg : String)
      result = tablets.find { |t| t.match?(arg) }

      result.nil? ? Tablet::NONE : result
    end

    protected def self.traverse(tablets : Tablets, args : Array(String), & : Tablet -> Bool) : Tablet
      current = Tablet::NONE

      while args.size > 1
        arg = args.shift

        Tabular::Log::Debug.show "ARG: #{arg} | LEFT: #{args}"

        next if current.next do |a|
          current = Tablet::NONE if a.match!(arg)
        end

        current = find(tablets, arg)
        next if current.kind.none?

        tablets.delete current unless current.repeatable?
        next unless current.kind.runnable?

        yield current
        break
      end

      current
    end

    protected def self.directives(tablets : Tablets)
      tablets.reduce(Directive::None) { |a, t| a | t.directives }
    end
  end
end
