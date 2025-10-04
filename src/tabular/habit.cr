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

    protected def form(@args : Array(String) = ARGV) : Bool
      with self yield self
      reply
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
    # - *delimiters*: Ad hoc delimiters that will override [`Tabular.delimiters`][Tabular.delimiters].
    def option(name : String, *aliases : String, help = "", directives : Directable? = nil, delimiters = Tabular.delimiters)
      @tablets << Tablet.new :option, name, aliases, help, directives: directives, delimiters: delimiters
    end

    # Create a [`Option`][Tabular::Kind::Option]-flavoured [`Tablet`][Tabular::Tablet] with expected
    # [`Argument`][Tabular::Kind::Argument]-flavoured [`Tablet`][Tabular::Tablet](s).
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
    # - *delimiters*: Ad hoc delimiters that will override [`Tabular.delimiters`][Tabular.delimiters].
    def option(name : String, *aliases, help = "", delimiters = Tabular.delimiters, &)
      opt = Tablet.new Kind::Option, name, aliases, help, delimiters: delimiters

      with opt.habit yield

      @tablets << opt
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
      @tablets << Tablet.new :argument, "", choices, help, directives: directives
    end

    # Create a [`Command`][Tabular::Kind::Command]-flavoured [`Tablet`][Tabular::Tablet].
    #
    # - *name*: See [`Tablet#name`][Tabular::Tablet#name].
    # - *aliases*: See [`Tablet#aliases`][Tabular::Tablet#aliases].
    # - *help*: See [`Tablet#help`][Tabular::Tablet#help].
    # - *directives*: See [`Directive`][Tabular::Directive].
    def command(name : String, aliases = [] of String, help = "", directives : Directable? = nil)
      @tablets << Tablet.new :command, name, aliases, help, directives: directives
    end

    # Create a [`Tablet`][Tabular::Tablet].
    def tablet(kind : Kind, *args, **kwargs)
      @tablets << Tablet.new kind, *args, **kwargs
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

    private def reply : Bool
      args = @args
      return true if args.empty?

      tablets = @tablets
      current = Habit.traverse(tablets, args) do |runnable|
        Tabular::Log::Debug.show "RUN: #{runnable}"
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

        tablets.delete current
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
