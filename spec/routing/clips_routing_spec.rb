require "spec_helper"

describe ClipsController do
  describe "routing" do

    it "routes to #index" do
      get("/clips").should route_to("clips#index")
    end

    it "routes to #new" do
      get("/clips/new").should route_to("clips#new")
    end

    it "routes to #show" do
      get("/clips/1").should route_to("clips#show", :id => "1")
    end

    it "routes to #edit" do
      get("/clips/1/edit").should route_to("clips#edit", :id => "1")
    end

    it "routes to #create" do
      post("/clips").should route_to("clips#create")
    end

    it "routes to #update" do
      put("/clips/1").should route_to("clips#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/clips/1").should route_to("clips#destroy", :id => "1")
    end

  end
end
