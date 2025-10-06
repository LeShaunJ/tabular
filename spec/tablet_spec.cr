require "./spec_helper"
require "../src/tabular/*"

struct Tabular::Tablet
  def with_habit
    with @habit yield
    self
  end
end

Spectator.describe Tabular::Tablet do
  def candidate(tablet : Tabular::Tablet, arg : String)
    result = [] of String
    tablet.candidate arg do |t|
      result << t
    end
    result
  end

  context "with any Tablet" do
    let(kind) { Tabular::Kind::None }
    let(name) { "name" }
    let(aliases) { ["alias"] }
    let(help) { "a dummy test" }
    let(directives) { Tabular::Directive::NoFile }
    let(repeat) { true }
    subject { Tabular::Tablet.new kind, name, aliases, help, repeatable: repeat }

    describe "#kind" do
      it "has the correct _kind_" do
        expect(subject.kind).to eq(kind)
      end
    end

    describe "#name" do
      it "has the correct _name_" do
        expect(subject.name).to eq(name)
      end
    end

    describe "#aliases" do
      it "has the correct _aliases_" do
        expect(subject.aliases).to eq([name].concat(aliases).to_set)
      end
    end

    describe "#help" do
      it "has the correct _help_" do
        expect(subject.help).to eq(help)
      end
    end

    describe "#directives" do
      it "has the correct _directives_" do
        expect(subject.directives).to eq(directives)
      end
    end

    describe "#repeatable?" do
      it "is #{repeat}" do
        expect(subject.repeatable?).to eq(repeat)
      end
    end

    describe "#form?" do
      it "is empty" do
        expect(subject.form?).to eq(false)
      end
    end

    describe "#next" do
      it "is nil" do
        result : Tabular::Tablet? = nil
        subject.next do |tablet|
          result = tablet
        end
        expect(result).to eq(nil)
      end
    end
  end

  context "with Tabular::Kind::Option" do
    let(kind) { Tabular::Kind::Option }
    let(name) { "--opt" }
    let(aliases) { ["--alias", "-o"] }
    subject { Tabular::Tablet.new(kind, name, aliases).with_habit { argument } }

    describe "#form?" do
      it "is not empty" do
        expect(subject.form?).to eq(true)
      end
    end

    describe "#next" do
      it "is not nil" do
        result : Tabular::Tablet? = nil
        subject.next do |tablet|
          result = tablet
        end
        expect(result).to ne(nil)
      end
    end

    context "when arg.empty?" do
      let(arg) { "" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields no candidates" do
          expect(candidates.size).to eq 0
        end
      end

      describe "#match?" do
        it "is false" do
          expect(subject.match?(arg)).to eq false
        end
      end
    end

    context "when arg is '-'" do
      let(arg) { "-" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields all candidates" do
          expect(candidates.size).to eq subject.aliases.size
        end
      end

      describe "#match!" do
        it "raises an error" do
          expect { subject.match!(arg) }.to raise_error Tabular::Error::Match
        end
      end

      describe "#match?" do
        it "is false" do
          expect(subject.match?(arg)).to eq false
        end
      end
    end

    context "when arg is '--opt'" do
      let(arg) { "--opt" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields one candidate" do
          expect(candidates.size).to eq 1
        end
      end

      describe "#match!" do
        it "returns self" do
          expect(subject.match!(arg)).to ne nil
        end
      end

      describe "#match?" do
        it "is true" do
          expect(subject.match?(arg)).to eq true
        end
      end
    end
  end

  context "with Tabular::Kind::Argument" do
    let(kind) { Tabular::Kind::Argument }
    let(name) { "yaml" }
    let(aliases) { ["yml", "json"] }
    subject { Tabular::Tablet.new kind, name, aliases, directives: :no_file }

    context "when arg.empty?" do
      let(arg) { "" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields all candidates" do
          expect(candidates.size).to eq subject.aliases.size
        end
      end

      describe "#match?" do
        it "is false" do
          expect(subject.match?(arg)).to eq false
        end
      end
    end

    context "when arg is 'y'" do
      let(arg) { "y" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields some candidates" do
          expect(candidates.size).to eq 2
        end
      end

      describe "#match!" do
        it "raises an error" do
          expect { subject.match!(arg) }.to raise_error Tabular::Error::Match
        end
      end

      describe "#match?" do
        it "is false" do
          expect(subject.match?(arg)).to eq false
        end
      end
    end

    context "when arg is 'yaml'" do
      let(arg) { "yaml" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields one candidate" do
          expect(candidates.size).to eq 1
        end
      end

      describe "#match!" do
        it "returns self" do
          expect(subject.match!(arg)).to ne nil
        end
      end

      describe "#match?" do
        it "is true" do
          expect(subject.match?(arg)).to eq true
        end
      end
    end
  end

  context "with Tabular::Kind::Command" do
    let(kind) { Tabular::Kind::Command }
    let(name) { "cmd1" }
    let(aliases) { ["alias1", "alias2"] }
    subject { Tabular::Tablet.new kind, name, aliases }

    context "when arg.empty?" do
      let(arg) { "" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields all candidates" do
          expect(candidates.size).to eq subject.aliases.size
        end
      end

      describe "#match?" do
        it "is false" do
          expect(subject.match?(arg)).to eq false
        end
      end
    end

    context "when arg is 'alias'" do
      let(arg) { "alias" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields some candidates" do
          expect(candidates.size).to eq 2
        end
      end

      describe "#match!" do
        it "raises an error" do
          expect { subject.match!(arg) }.to raise_error Tabular::Error::Match
        end
      end

      describe "#match?" do
        it "is false" do
          expect(subject.match?(arg)).to eq false
        end
      end
    end

    context "when arg is 'alias2'" do
      let(arg) { "alias2" }

      describe "#candidate" do
        let(candidates) { candidate(subject, arg) }

        it "yields one candidate" do
          expect(candidates.size).to eq 1
        end
      end

      describe "#match!" do
        it "returns self" do
          expect(subject.match!(arg)).to ne nil
        end
      end

      describe "#match?" do
        it "is true" do
          expect(subject.match?(arg)).to eq true
        end
      end
    end
  end
end
