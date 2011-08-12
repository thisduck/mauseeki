require 'spec_helper'

describe "lists/index.html.erb" do
  before(:each) do
    assign(:lists, [
      stub_model(List),
      stub_model(List)
    ])
  end

  it "renders a list of lists" do
    render
  end
end
