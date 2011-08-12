require 'spec_helper'

describe "clips/edit.html.erb" do
  before(:each) do
    @clip = assign(:clip, stub_model(Clip))
  end

  it "renders the edit clip form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => clips_path(@clip), :method => "post" do
    end
  end
end
