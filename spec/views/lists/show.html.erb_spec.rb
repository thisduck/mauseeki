require 'spec_helper'

describe "lists/show.html.erb" do
  before(:each) do
    @list = assign(:list, stub_model(List))
  end

  it "renders attributes in <p>" do
    render
  end
end
