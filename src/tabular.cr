require "./tabular/*"

# The `Tabular` library.
module Tabular(T)
  # Define a set of [`Tablets`][Tabular::Tablets] and an optional [`Habit#dispatch`][Tabular::Habit#dispatch].
  #
  # ```crystal
  # Tabular.form do
  #   option "--opt1" "-f", help: "a flag parameter"
  #
  #   option "--opt2" "-a", help: "a optiona with argument" { argument }
  #
  #   option "--opt2", help: "a flag with multiple arguments" do
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
  def self.form(args : Array(String) = ARGV) : Bool
    Tabular::Habit.new.form args do |formation|
      with formation yield
    end
  end
end
