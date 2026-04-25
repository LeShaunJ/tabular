module Tabular(T)
  # Return the global string of characters that may delimit a [`Option`][Tabular::Kind::Option]-flavour
  # [`Tablet`][Tabular::Tablet].
  protected def self.delimiters : String
    @@delimiters ||= ""
  end

  # Specify the global string of characters that may delimit a [`Option`][Tabular::Kind::Option]-flavour
  # [`Tablet`][Tabular::Tablet].
  #
  # ```
  # # Allows for something like `--option=`
  # Tabular.delimiters = "="
  # # Allows for something like `-option:`
  # Tabular.delimiters = ":"
  # # Allows for all of the above
  # Tabular.delimiters = ":="
  # ```
  protected def self.delimiters=(value : String)
    @@delimiters = value
  end

  # Represents a parameter whose name and aliases may be suggested and matched during tab completion.
  struct Tablet
    # Basically, [`Tablet?`][Tabular::Tablet] minus the baggage.
    NONE = Tablet.new(:none, directives: :no_file)

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

    protected setter :aliases
    protected getter :habit
    protected getter :delimiters

    # Create a new [`Tablet`][Tabular::Tablet].
    #
    # - *kind*: See [`#kind`][Tabular::Tablet#kind].
    # - *name*: See [`#name`][Tabular::Tablet#name].
    # - *aliases*: See [`#aliases`][Tabular::Tablet#aliases].
    # - *help*: See [`#help`][Tabular::Tablet#help].
    # - *directives*: See [`#directives`][Tabular::Tablet#directives].
    # - *delimiters*: Ad hoc delimiters that will override [`Habit#delimiters`][Tabular::Habit#delimiters].
    def initialize(kind : Kind, @name = "", aliases = [] of String, help = "", directives : Directable? = nil, delimiters = Tabular.delimiters, @repeatable = false)
      @kind = Kind.from_value(kind)
      @aliases = [name].concat(aliases).reject(&.empty?).to_set
      @help = truncate(help)
      @directives = directives.nil? ? @kind.directives : Directive.from_value(directives)
      @delimiters = delimiters.empty? ? "" : "[#{delimiters}]"
      @habit = Habit.new
    end

    # Return `true`, the [`Tablet`][Tabular::Tablet] may appear more than once.
    def repeatable?
      @repeatable
    end

    # Yield suggestions for any names that contain *word*.
    def candidate(word : String, prefix : String = "", & : String ->)
      return if skip?(word)
      return yield "" if @aliases.empty? && always_suggest?
      return @aliases.each { |name| yield show(name) } if always_suggest?

      @aliases.each do |name|
        next unless name.starts_with?(word)

        yield show(name)
      end
    end

    # Returns `self` if *word* is an exact match of any names. Otherwise, raise [`Error::Match`][Tabular::Error::Match].
    def match!(word : String)
      raise Error::Match.new word unless match?(word)

      self
    end

    # Return `true` if *word* is an exact match of any names.
    def match?(word : String) : Bool
      return true if passthru? || @aliases.empty?

      @aliases.find_value(false) do |name|
        delimited!(word, name) || name == word
      end
    end

    # Return `true` if *word* is a delimited match of any names.
    def delimits?(word : String) : Bool
      @aliases.find_value(false) { |name| delimited?(word, name) }
    end

    # Return `true` if a nested form exists.
    def form?
      @has_form ||= !@habit.tablets.empty?
    end

    # For an [`Option`][Tabular::Kind::Option]-flavoured [`Tablet`][Tabular::Tablet] with `#form?`, yield the next
    # [`Argument`][Tabular::Kind::Argument]-flavoured [`Tablet`][Tabular::Tablet] to the specified `&block`.
    def next(&)
      return if @habit.tablets.empty?

      tablet = @habit.tablets.first
      @habit.tablets.delete tablet

      yield tablet
    end

    # Return the specified *word* and possible prefix, if delimited.
    def to_prefix(word : String) : Tuple(String, String)
      raise Regex::Error.new if @delimiters.empty?

      _, prefix, arg = word.match!(/^(.+?#{@delimiters})(.*)$/)
      {arg, prefix}
    rescue e : Regex::Error
      {word, ""}
    end

    def to_s(io : IO)
      io << show
    end

    private def skip?(word : String)
      word.empty? && kind.option?
    end

    private def delimited!(word : String, name : String)
      return false unless delimited?(word, name)

      full, arg = /^#{name}#{@delimiters}(.*)$/.match!(word)
      raise Error::Match.new word if arg.empty?

      is_match = @habit.tablets.all? { |tablet| tablet.match? arg }
      raise Error::Match.new word unless is_match

      @habit.tablets.clear
      is_match
    rescue ex : Regex::Error | IndexError
      raise Error::Match.new word, ex
    end

    private def delimited?(word : String, name : String)
      return false if @delimiters.empty?
      return false unless form?

      /^#{name}#{@delimiters}/.matches?(word)
    end

    private def always_suggest?
      @always_suggest ||= (directives.relay? || passthru?).as(Bool)
    end

    private def passthru?
      @passthru ||= (directives.filter_ext? || directives.filter_dir?).as(Bool)
    end

    private def show(name : String = @name)
      "#{(name.empty? ? @aliases.join('|') : name)}\t#{@help}".rstrip "\t"
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
