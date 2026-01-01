require "./spec_helper"

describe Mcp::Protocol::Id do
  it "creates a key for nil" do
    Mcp::Protocol::Id.key(nil).should be_nil
  end

  it "creates a key for string id" do
    Mcp::Protocol::Id.key("req-1").should eq "req-1"
  end

  it "creates a key for int id" do
    Mcp::Protocol::Id.key(123_i64).should eq "123"
  end
end

