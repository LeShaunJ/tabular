require "./tabular/*"

# The `Tabular` library.
module Tabular(T)
  extend self

  # Define the set of [`Tablets`][Tabular::Tablets] and an optional [`Habit#dispatch`][Tabular::Habit#dispatch]
  # and process the given *words* sent from the command-line:
  #
  # ```
  # Tabular.form do
  #   option "--opt1" "-f", help: "a flag parameter"
  #
  #   option "--opt2" "-a", help: "a optiona with argument" { argument }
  #
  #   option "--opt3", help: "a flag with multiple arguments" do
  #     argument "arg1_choice1", "arg1_choice2", "arg1_choice3"
  #     argument "arg2_choice1", "arg2_choice2"
  #   end
  #
  #   command "cmd1", "cmd1_alias", help: "a subcommand"
  #
  #   # An optional handler for command tablets
  #   dispatch do |command|
  #     if command.name == "cmd1"
  #       Subcommand1.complete ARGV
  #     end
  #   end
  # end
  # ```
  def form(words : Array(String) = ARGV, &) : Bool
    Tabular::Habit.new.form words do |formation|
      with formation yield
    end
  end

  # Define a completer as an instance method, *name*, with *&block* as the [`form`][Tabular.form]:
  #
  # ```
  # class MyClass
  #   Tabular.define my_completer do
  #     option "--help"
  #     command "sub_cmd1"
  #     command "sub_cmd2"
  #   end
  # end
  # ```
  # This is equivalent to:
  # ```
  # class MyClass
  #   def my_completer(words : Array(String) = ARGV) : Bool
  #     Tabular.form words do
  #       option "--help"
  #       command "sub_cmd1"
  #       command "sub_cmd2"
  #     end
  #   end
  # end
  # ```
  macro define(name, &block)
    def {{name}}(words : Array(String) = ARGV) : Bool
      Tabular.form words do
        {{block.body}}
      end
    end
  end

  # Define a [`#relay`][Tabular::Habit#relay] completer as an instance method, *name*:
  #
  # ```
  # class MyClass
  #   Tabular.relay my_completer
  # end
  # ```
  # This is equivalent to:
  # ```
  # class MyClass
  #   def my_completer(words : Array(String) = ARGV) : Bool
  #     Tabular.form words do
  #       relay
  #     end
  #   end
  # end
  # ```
  macro relayer(name)
    ::Tabular.define {{name}} do relay end
  end

  # Define a [`#relay`][Tabular::Fragments#install] completer, *name*, as an instance method:
  #
  # ```
  # class MyClass
  #   Tabular.installer my_installer
  # end
  # ```
  # This is equivalent to:
  # ```
  # class MyClass
  #   def my_installer(words : Array(String) = ARGV) : Bool
  #     Tabular::Fragments.install words
  #   end
  # end
  # ```
  macro installer(name)
    def {{name}}(words : Array(String) = ARGV) : Bool
      Tabular::Fragments.install words
    end
  end
end
