require "./spec_helper"
require "../src/tabular/log"

Spectator.describe Tabular::Log do
  let(io) { IO::Memory.new }
  let(msg) { "hello, world" }

  before_each { Tabular::Log.dummy = io }
  after_each { io.clear }

  def self.levels; Tabular::Log.names; end

  describe "#show" do
    sample levels do |level|
      let(logger) { Tabular::Log.parse(level) }
      let(value) { logger.to_u32 }
      let(name) { level.upcase }

      it "prints a formatted #{name} message" do
        Tabular::Log.level = value
        logger.show msg
        expect(io.rewind.gets_to_end).to match(/^(\e\[\d+m)?#{logger.to_s.upcase}\b/)
      end

      it "prints NO formatted #{name} message" do
        Tabular::Log.level = value - 1
        logger.show msg
        expect(io.rewind.gets_to_end).to be_empty
      end
    end
  end

  describe "#send" do
    sample levels do |level|
      let(logger) { Tabular::Log.parse(level) }
      let(value) { logger.to_u32 }
      let(name) { level.upcase }

      it "prints a journald #{name} message" do
        Tabular::Log.level = value
        logger.send msg
        expect(io.rewind.gets_to_end).to match(/^<#{value}> #{msg}/)
      end

      it "prints NO journald #{name} message" do
        Tabular::Log.level = value - 1
        logger.send msg
        expect(io.rewind.gets_to_end).to be_empty
      end
    end
  end

  describe "self.out" do
    it "it prints a message" do
      Tabular::Log.out msg
      expect(io.rewind.gets_to_end).to eq("#{msg}\n")
    end

    context "with self.silence" do
      it "it prints NO message" do
        Tabular::Log.silence
        Tabular::Log.out msg
        expect(io.rewind.gets_to_end).to be_empty
      end
    end
  end
end
