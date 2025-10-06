module Tabular(T)
  # A bit map representing the different behaviors the shell can be instructed
  # to have once completions have been provided.
  @[Flags]
  enum Directive
    # Indicates to let the shell perform its default behavior after completions have been provided.
    None = 0
    # Indicates an error occurred and completions should be ignored.
    Error
    # Indicates that the shell should not add a space after the completion even if there is a single completion provided.
    NoSpace
    # Indicates that the shell should not provide file completion even when no completion is provided.
    NoFile
    # Indicates that the provided completions should be used as file extension filters.
    FilterExt
    # Indicates that only directory names should be provided in file completion.
    FilterDir
    # Indicates that the shell should preserve the order in which the completions are provided
    KeepOrder

    # Returns the `String` representation that will be sent to the shell.
    def show; ":#{value}"; end

    # :nodoc:
    def self.from_value(value : self); value; end
    # :nodoc:
    def self.from_value(value : Nil); Directive::None; end
    # :nodoc:
    def self.from_value(value : Symbol)
      self.parse(value.to_s)
    end
  end

  private alias Directable = Directive | Int32

  # Specifiers that determine the functionality of a [`Tablet`][Tabular::Tablet].
  enum Kind

    # :nodoc:
    None
    # Specifies that a [`Tablet`][Tabular::Tablet] represents an [`#option`][Tabular::Habit#option] parameter.
    Option
    # Specifies that a [`Tablet`][Tabular::Tablet] represents an [`argument`][Tabular::Habit#argument] parameter.
    Argument
    # Specifies that a [`Tablet`][Tabular::Tablet] represents an [`subcommand`][Tabular::Habit#subcommand] parameter.
    Command

    # Returns `true` if the [`Tablet`][Tabular::Tablet] represented by the [`Kind`][Tabular::Kind] should hand control back to
    # the CLI when matched. Only [`Command`][Tabular::Kind::Command] is runnable.
    def runnable?
      self.command?
    end

    # Returns the default [`Directive`][Tabular::Directive] of the [`Kind`][Tabular::Kind].
    #
    # - [`Argument`][Tabular::Kind::Argument] — [`None`][Tabular::Directive::None]
    # - All others — [`NoFile`][Tabular::Directive::NoFile]
    def directives
      case self
      when Kind::Argument then
        KIND_DIRECTIVES[self] ||= Directive.from_value(0)
      else
        KIND_DIRECTIVES[self] ||= Directive::NoFile
      end
    end

    # :nodoc:
    def self.from_value(value : self); value; end
    # :nodoc:
    def self.from_value(value : Symbol)
      self.parse(value.to_s)
    end
  end

  private KIND_DIRECTIVES = {} of Kind => Directive
end
