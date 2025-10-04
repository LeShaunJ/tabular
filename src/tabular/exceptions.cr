module Tabular(T)
  # A collection of exceptions specific to `Tabular`.
  module Error
    # A base exception that all [`Error`][Tabular::Error] exceptions
    # can be caught with.
    class Any < Exception; end

    # Raised when an argument that must [`Tablet`][Tabular::Tablet] does not.
    class Match < Any; end

    # Raised when method arguments are incorrect or missing.
    class Argument < Any; end

    # Raised on issues with the installer.
    class Install < Any; end

    # Raised when a configuration is unsupported.
    class Support < Any; end
  end
end
