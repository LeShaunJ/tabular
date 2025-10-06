require "./spec_helper"
require "../src/tabular/enums"

Spectator.describe Tabular::Kind do
  subject { Tabular::Kind }
  let(none) { Tabular::Kind::None }

  describe "self.from_value" do
    context "with self" do
      it "is self" do
        expect(subject.from_value(none)).to eq(none)
      end
    end

    context "with :none" do
      it "is Kind::None" do
        expect(subject.from_value(:none)).to eq(none)
      end
    end
  end

  context "when member is ::Command" do
    subject { Tabular::Kind::Command }

    describe "#directives" do
      it "is Directive::NoFile" do
        expect(subject.directives).to eq(Tabular::Directive::NoFile)
      end
    end

    describe "#runnable?" do
      it "is Kind::None" do
        expect(subject.runnable?).to eq(true)
      end
    end
  end
end
