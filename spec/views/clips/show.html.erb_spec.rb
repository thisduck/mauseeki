require 'spec_helper'

describe "clips/show.html.erb" do
  before(:each) do
    @clip = assign(:clip, stub_model(Clip))
  end

  it "renders attributes in <p>" do
    render
  end
end
