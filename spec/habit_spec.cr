require "./spec_helper"
require "../src/tabular"

class Tabular::Habit
  def self.test; new; end
end

alias Kind = Tabular::Kind
alias Directive = Tabular::Directive
alias Tablet = Tabular::Tablet

Spectator.describe Tabular::Habit do
  subject { Tabular::Habit.test }

  describe "#delimiters" do
    let(delim) { ":=" }

    it "sets the global delimiters" do
      subject.delimiters delim
      expect(subject.delimiters).to eq(delim)
    end
  end

  def self.dir_samples : Array(Tuple(Kind, Directive, Directive))
    [ { Kind::Option,   Directive::FilterDir },
      { Kind::Argument, Directive::KeepOrder },
      { Kind::Command,  Directive::NoSpace   },
    ].map do |k, d|
      {k, d, k.directives}
    end
  end

  describe "#directives" do
    sample dir_samples do |kind, directive, previous|
      after_each  { subject.directives kind, previous }

      it "sets the global directives" do
        subject.directives kind, directive
        expect(subject.directives(kind)).to eq(directive)
      end
    end
  end

  describe "#tablet" do
    let(tablet) { subject.tablet Kind::None }

    it "creates a Tablet" do
      expect(tablet.kind).to eq(Kind::None)
    end
  end

  describe "#option" do
    let(name) { "--opt" }
    let(tablet) { subject.option name }

    it "creates an Option" do
      expect(tablet.kind).to eq(Kind::Option)
      expect(tablet.name).to eq(name)
    end

    context "with block" do
      let(tablet) {
        subject.option name do
          argument
        end
      }

      it "creates an Option with Argument" do
        expect(tablet.kind).to eq(Kind::Option)
        expect(tablet.name).to eq(name)
        expect(tablet.form?).to eq(true)
        tablet.next do |current|
          expect(current).to ne(nil)
        end
      end
    end
  end

  describe "#argument" do
    let(tablet) { subject.argument }

    it "creates an Argument" do
      expect(tablet.kind).to eq(Kind::Argument)
    end
  end

  describe "#command" do
    let(name) { "cmd" }
    let(tablet) { subject.command name }

    it "creates an Command" do
      expect(tablet.kind).to eq(Kind::Command)
      expect(tablet.name).to eq(name)
    end

    context "with block" do
      let(tablet) {
        subject.command name do
          option "--opt"
          argument
        end
      }

      it "creates an Command with formation" do
        expect(tablet.kind).to eq(Kind::Command)
        expect(tablet.name).to eq(name)
        expect(tablet.form?).to eq(true)
        tablet.next do |current|
          expect(current).to ne(nil)
        end
      end
    end
  end

  describe "#installer" do
    let(tablet) { subject.installer }

    it "creates an Installer" do
      expect(tablet.kind).to eq(Kind::Command)
      expect(tablet.name).to eq("completion")
      expect(tablet.form?).to eq(true)
      tablet.next do |current|
        expect(current).to ne(nil)
      end
    end
  end

  describe "#size" do
    it "returns the size" do
      expect(subject.size).to eq(0)
    end
  end
end
