require 'spec_helper'

describe "clips/index.html.erb" do
  before(:each) do
    assign(:clips, [
      stub_model(Clip),
      stub_model(Clip)
    ])
  end

  it "renders a list of clips" do
    render
  end
end
