module Tabular(T)
  # Return the global string of characters that may delimit a [`Option`][Tabular::Kind::Option]-flavour
  # [`Tablet`][Tabular::Tablet].
  protected def self.delimiters : String
    @@delimiters ||= ""
  end

  # Specify the global string of characters that may delimit a [`Option`][Tabular::Kind::Option]-flavour
  # [`Tablet`][Tabular::Tablet].
  #
  # ```crystal
  # # Allows for something like `--option=`
  # Tabular.delimiters = "="
  # # Allows for something like `-option:`
  # Tabular.delimiters = ":"
  # # Allows for all of the above
  # Tabular.delimiters = ":="
  # ```
  protected def self.delimiters=(value : String)
    Log::Debug.show "REZMERE"
    @@delimiters = value
  end

  # Represents a parameter whose name and aliases may be suggested and matched during tab completion.
  struct Tablet
    # Basically, [`Tablet?`][Tabular::Tablet] minus the baggage.
    NONE = Tablet.new(:none)

    @kind : Kind
    @aliases : Set(String)
    @help : String
    @directives : Directive
    @habit = Habit.new

    # The representation of the [`Tablet`][Tabular::Tablet].
    getter :kind
    # The name of the parameter the [`Tablet`][Tabular::Tablet] represents.
    getter :name
    # A list of additional names the [`Tablet`][Tabular::Tablet] will suggest/match.
    getter :aliases
    # The description of the parameter the [`Tablet`][Tabular::Tablet] represents.
    getter :help
    # Additional directives the [`Tablet`][Tabular::Tablet] will send to the shell if suggested.
    getter :directives

    protected getter :habit

    # Create a new [`Tablet`][Tabular::Tablet].
    #
    # - *kind*: See [`#kind`][Tabular::Tablet#kind].
    # - *name*: See [`#name`][Tabular::Tablet#name].
    # - *aliases*: See [`#aliases`][Tabular::Tablet#aliases].
    # - *help*: See [`#help`][Tabular::Tablet#help].
    # - *directives*: See [`#directives`][Tabular::Tablet#directives].
    # - *delimiters*: Ad hoc delimiters that will override [`Tabular.delimiters`][Tabular.delimiters].
    def initialize(kind : Kind, @name = "", aliases = [] of String, help = "", directives : Directable? = nil, delimiters = Tabular.delimiters, @repeatable = false)
      @kind = Kind.from_value(kind)
      @aliases = [name].concat(aliases).reject(&.empty?).to_set
      @help = truncate(help)
      @directives = directives.nil? ? @kind.directives : Directive.from_value(directives)
      @delimiters = delimiters.empty? ? "" : "[#{delimiters}]?"
      @habit = Habit.new
    end

    # Return `true`, the [`Tablet`][Tabular::Tablet] may appear more than once.
    def repeatable?
      @repeatable
    end

    # Yield suggestions for any names that contain *arg*.
    def candidate(arg : String, & : String -> )
      return if skip?(arg)

      @aliases.each do |a|
        next unless passthru? || a.starts_with?(arg)

        yield show(a)
      end
    end

    # Returns `self` if *arg* is an exact match of any names. Otherwise, raise [`Error::Match`][Tabular::Error::Match].
    def match!(arg : String)
      raise Error::Match.new "No match for '#{arg}'" unless match?(arg)

      self
    end

    # Return `true` if *arg* is an exact match of any names.
    def match?(arg : String) : Bool
      return true if passthru? || @aliases.empty?

      @aliases.find_value(false) do |a|
        delimited?(arg, a) || a == arg
      end
    end

    # Return `true` if a nested form exists.
    def form?
      @has_form ||= !@habit.tablets.empty?
    end

    # For an [`Option`][Tabular::Kind::Option]-flavoured [`Tablet`][Tabular::Tablet] with `#form?`, yield the next
    # [`Argument`][Tabular::Kind::Argument]-flavoured [`Tablet`][Tabular::Tablet] to the specified `&block`.
    def next
      return if @habit.tablets.empty?

      tablet = @habit.tablets.first
      @habit.tablets.delete tablet

      yield tablet
    end

    def to_s(io : IO)
      io << show
    end

    private def skip?(arg : String)
      arg.empty? && kind.option?
    end

    private def delimited?(arg : String, name : String)
      return false if @delimiters.empty?
      return false unless form?

      /^#{name}#{@delimiters}$/.matches?(arg)
    end

    private def passthru?
      @passthru ||= (kind.argument? && (directives.filter_ext? || directives.filter_dir?)).as(Bool)
    end

    private def show(name : String = @name)
      "#{name}\t#{@help}".rstrip "\t"
    end

    private def truncate(text : String)
      lines = text.lines
      text = "#{lines.first}..." if lines.size > 1

      text.gsub(/\t/, "  ")
    end
  end

  # A collection of [`Tablet`][Tabular::Tablet] instances.
  alias Tablets = Set(Tabular::Tablet)
end
