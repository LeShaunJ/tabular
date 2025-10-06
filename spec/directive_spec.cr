require "./spec_helper"
require "../src/tabular/enums"

Spectator.describe Tabular::Directive do
  subject { Tabular::Directive }
  let(none) { Tabular::Directive::None }

  describe "self.from_value" do
    context "with self" do
      it "is self" do
        expect(subject.from_value(none)).to eq(none)
      end
    end

    context "with Nil" do
      it "is Directive::None" do
        expect(subject.from_value(nil)).to eq(none)
      end
    end

    context "with :none" do
      it "is Directive::None" do
        expect(subject.from_value(:none)).to eq(none)
      end
    end
  end

  context "when member is ::None" do
    subject { Tabular::Directive::None }

    describe "#show" do
      it "is Directive::None" do
        expect(subject.show).to eq(":#{subject.value}")
      end
    end
  end
end
